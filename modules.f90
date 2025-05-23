! Modules used by cmbmain and other routines. 

!     Code for Anisotropies in the Microwave Background
!     by Antony Lewis (http://cosmologist.info) and Anthony Challinor
!     See readme.html for documentation.
!
!     Based on CMBFAST  by  Uros Seljak and Matias Zaldarriaga, itself based
!     on Boltzmann code written by Edmund Bertschinger, Chung-Pei Ma and Paul Bode.
!     Original CMBFAST copyright and disclaimer:
!
!     Copyright 1996 by Harvard-Smithsonian Center for Astrophysics and
!     the Massachusetts Institute of Technology.  All rights reserved.
!
!     THIS SOFTWARE IS PROVIDED "AS IS", AND M.I.T. OR C.f.A. MAKE NO
!     REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED.
!     By way of example, but not limitation,
!     M.I.T. AND C.f.A MAKE NO REPRESENTATIONS OR WARRANTIES OF
!     MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT
!     THE USE OF THE LICENSED SOFTWARE OR DOCUMENTATION WILL NOT INFRINGE
!     ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR OTHER RIGHTS.
!
!     portions of this software are based on the COSMICS package of
!     E. Bertschinger.  See the LICENSE file of the COSMICS distribution
!     for restrictions on the modification and distribution of this software.


module ModelParams
  use precision
  use Ranges
  use InitialPower
  use Reionization
  use Recombination
  use Errors

  implicit none
  public

  character(LEN=*), parameter :: version = 'Nov13'

  integer :: FeedbackLevel = 0 !if >0 print out useful information about the model

  logical, parameter :: DebugMsgs=.false. !Set to true to view progress and timing

  logical, parameter :: DebugEvolution = .false. !Set to true to do all the evolution for all k

  real(dl) :: DebugParam = 0._dl !not used but read in, useful for parameter-dependent tests

  logical ::  do_bispectrum  = .false.
  logical, parameter :: hard_bispectrum = .false. ! e.g. warm inflation where delicate cancellations

  logical, parameter :: full_bessel_integration = .false. !(go into the tails when calculating the sources)

  integer, parameter :: Nu_int = 0, Nu_trunc=1, Nu_approx = 2, Nu_best = 3
  !For CAMBparams%MassiveNuMethod
  !Nu_int: always integrate distribution function
  !Nu_trunc: switch to expansion in velocity once non-relativistic
  !Nu_approx: approximate scheme - good for CMB, but not formally correct and no good for matter power
  !Nu_best: automatically use mixture which is fastest and most accurate

  integer, parameter :: max_Nu = 5 !Maximum number of neutrino species
  integer, parameter :: max_transfer_redshifts = 500!RL 07/11/2023: default 500 ! COSMOSIS - alter number of transfer redshifts 
  !    integer, parameter :: max_transfer_redshifts = 150
  integer, parameter :: fileio_unit = 13 !Any number not used elsewhere will do
  integer, parameter :: outNone=1


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! Ultra-light axion parameters
  !
  !DM
  !Size of axion integration array (number of time slices for homogeneous scalar field evolution)   
  !!integer, parameter :: ntable = 300 ! RH added this so it is callable everywhere !RL: default is 5000
  !Number of scalar initial conditions to try to build a cubic spline
  !and thus determine correct initial condition for scalar field evolution
  integer, parameter:: nphi = 150 !RL: default 150
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  integer :: max_bessels_l_index  = 1000000
  real(dl) :: max_bessels_etak = 1000000*2

  real(dl), parameter ::  OutputDenominator =twopi
  !When using outNone the output is l(l+1)Cl/OutputDenominator

  Type(Regions) :: TimeSteps

  type TransferParams
     logical     ::  high_precision
     integer     ::  num_redshifts
     real(dl)    ::  kmax         !these are acutally q values, but same as k for flat
     integer     ::  k_per_logint ! ..
     real(dl)    ::  redshifts(max_transfer_redshifts)
     !JD 08/13 Added so both NL lensing and PK can be run at the same time
     real(dl)    ::  PK_redshifts(max_transfer_redshifts)
     real(dl)    ::  NLL_redshifts(max_transfer_redshifts)
     integer     ::  PK_redshifts_index(max_transfer_redshifts)
     integer     ::  NLL_redshifts_index(max_transfer_redshifts)
     integer     ::  PK_num_redshifts
     integer     ::  NLL_num_redshifts

  end type TransferParams

  !other variables, options, derived variables, etc.

  integer, parameter :: NonLinear_none=0, NonLinear_Pk =1, NonLinear_Lens=2
  integer, parameter :: NonLinear_both=3  !JD 08/13 added so both can be done

  ! Main parameters type
  type CAMBparams

     logical   :: WantCls, WantTransfer
     logical   :: WantScalars, WantTensors, WantVectors
     logical   :: DoLensing
     logical   :: want_zstar, want_zdrag     !!JH for updated BAO likelihood.
     logical   :: PK_WantTransfer             !JD 08/13 Added so both NL lensing and PK can be run at the same time
     integer   :: NonLinear
     logical   :: Want_CMB

     integer   :: Max_l, Max_l_tensor
     real(dl)  :: Max_eta_k, Max_eta_k_tensor
     ! _tensor settings only used in initialization,
     !Max_l and Max_eta_k are set to the tensor variables if only tensors requested

     real(dl)  :: omegab, omegac, omegav, omegan, omegaax, ma, m_ovH0, dfac
     real(dl)  :: a_osc, tau_osc, opac_tauosc, expmmu_tauosc, alpha_ax, r_val, omegah2_rad, amp_i, axfrac, omegada, Hinf !RL added tau at oscillation - the correct value will be calculated at init_background in equations_ppf
     real(dl) :: ah_osc, ahosc_ETA, A_coeff, tvarphi_c, tvarphi_cp, tvarphi_s, tvarphi_sp, wEFA_c !RL added background EFA parameters at the switch
     real(dl) :: A_coeff_alt !RL 043024 testing with changed A coeff
     real(dl) :: a_skip, dfac_skip, a_skipst !RL 012524 added for skipping recombination
     !Omega baryon, CDM, Lambda and massive neutrino and axions and masses    
     real(dl)  :: H0,TCMB,yhe,Num_Nu_massless
     real(dl)  :: H0_in_Mpc_inv, H0_eV !RL for the ease of computing KG in pert
     real(dl)  :: ratio

     !!real(dl), dimension(100000, 1, 6) :: RHCl_temp ! RH temp vector which will contain the axion iso spectrum ! RH
     !!real(dl), dimension(100000, 1, 6) :: RHCl_temp_lensed ! RH temp vector which will contain the axion iso spectrum ! RH
     !!real(dl), dimension(100000, 1, 6) :: RHCl_temp_tensor ! RH temp vector which will contain the axion iso spectrum ! RH

     !DM: tensor to scalar ratio is in CP for use in axion isocurvature i.c.'s 
     integer   :: Num_Nu_massive !sum of Nu_mass_numbers below
     integer   :: Nu_mass_eigenstates  !1 for degenerate masses
     logical   :: share_delta_neff !take fractional part to heat all eigenstates the same
     real(dl)  :: Nu_mass_degeneracies(max_nu)
     real(dl)  :: Nu_mass_fractions(max_nu) !The ratios of the total densities
     integer   :: Nu_mass_numbers(max_nu) !physical number per eigenstate
     real(dl)  :: Nu_massless_degeneracy !RL pasted DG's addition

     integer   :: Scalar_initial_condition
     !must be one of the initial_xxx values defined in GaugeInterface

     integer   :: OutputNormalization
     !outNone, or C_OutputNormalization=1 if > 1

     logical   :: use_axfrac, axion_isocurvature
     logical   :: AccuratePolarization
     !Do you care about the accuracy of the polarization Cls?

     logical   :: AccurateBB
     !Do you care about BB accuracy (e.g. in lensing)

     !Reionization settings - used if Reion%Reionization=.true.
     logical   :: AccurateReionization
     !Do you care about pecent level accuracy on EE signal from reionization?

     integer   :: MassiveNuMethod

     type(InitialPowerParams) :: InitPower  !see power_tilt.f90 - you can change this
     type(ReionizationParams) :: Reion
     type(RecombinationParams):: Recomb
     type(TransferParams)     :: Transfer

     real(dl) ::  InitialConditionVector(1:10) !Allow up to 10 for future extensions
     !ignored unless Scalar_initial_condition == initial_vector

     logical OnlyTransfers !Don't use initial power spectrum data, instead get Delta_q_l array
     !If true, sigma_8 is not calculated either

     logical DerivedParameters !calculate various derived parameters  (ThermoDerivedParams)

     !Derived parameters, not set initially
     type(ReionizationHistory) :: ReionHist

     logical flat,closed,open
     real(dl) omegak, omegar, grhor
     real(dl) curv,r, Ksign !CP%r = 1/sqrt(|CP%curv|), CP%Ksign = 1,0 or -1
     real(dl) tau0,chi0 !time today and rofChi(CP%tau0/CP%r)
!!!!!!!!!!!!!!!!!!!!!! 
     !Some more Ultra-light axion parameters       
     !
     !Scalar field EOS, log10(density), log10(scale_factor), spline buffer for scalar field EOS
     !and log10(density)
     
     !!real(dl), allocatable :: grhoax_table(:), grhoax_table_buff(:)
     !real(dl) :: adotoa_background(ntable), adotoa_background_buff(ntable) !RL for debugging
     !Adiabatic sound speed Pdot/rhodot and its spline buffer !RL commented out
     !real(dl) ::cs2_table(ntable),cs2_table_buff(ntable)
     real(dl) :: phiinit,aeq, ainit, lens_amp,rhorefp_ovh2, Prefp !RL added Prefp
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  end type CAMBparams

  type(CAMBparams) CP  !Global collection of parameters

  real(dl) scale !relative to CP%flat. e.g. for scaling lSamp%l sampling.

  logical ::call_again = .false.
  !if being called again with same parameters to get different thing

  !     grhom =kappa*a^2*rho_m0
  !     grhornomass=grhor*number of massless neutrino species
  !     taurst,taurend - time at start/end of recombination
  !     dtaurec - dtau during recombination
  !     adotrad - a(tau) in radiation era

  real(dl) grhom,grhog,grhor,grhob,grhoc,grhov,grhornomass,grhok
  real(dl) taurst,dtaurec,taurend, tau_maxvis,adotrad

  !Neutrinos
  real(dl) grhormass(max_nu)

  !     nu_masses=m_nu*c**2/(k_B*T_nu0)
  real(dl) :: nu_masses(max_nu)


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !Some more Ultra-light axion variables
  !Axions  log10 density today, a_osc =a when m=dfac*H (see background module
  !axion background.f90, drefp_hsq=axion density (not log) in same units
  !when a=a_osc -- allows simple a^-3 scaling to be applied throughout code
  real(dl) grhoax, a_osc, tau_osc, drefp_hsq !RL added tau at oscillation
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!
  real(dl) akthom !sigma_T * (number density of protons now)
  real(dl) fHe !n_He_tot / n_H_tot
  real(dl) Nnow


  integer :: ThreadNum = 0
  !If zero assigned automatically, obviously only used if parallelised

  !Parameters for checking/changing overall accuracy
  !If HighAccuracyDefault=.false., the other parameters equal to 1 corresponds to ~0.3% scalar C_l accuracy
  !If HighAccuracyDefault=.true., the other parameters equal to 1 corresponds to ~0.1% scalar C_l accuracy (at L>600)
  logical :: HighAccuracyDefault = .false.

  real(dl) :: lSampleBoost=1._dl
  !Increase lSampleBoost to increase sampling in lSamp%l for Cl interpolation

  real(dl) :: AccuracyBoost = 1._dl !1. is the default value. If you wish to change, change the one in the .ini file (RL: learned it the hard way!!)
  integer :: ntable = 5000 !RL 111123. ntable should be properly set in inidriver_axion.
  real(dl) :: aeq_LCDM !RL 031924, added for photon oscillation skipping
  real(dl), allocatable :: loga_table(:), phinorm_table(:), phidotnorm_table(:), phinorm_table_ddlga(:)
  real(dl), allocatable :: phidotnorm_table_ddlga(:), rhoaxh2ovrhom_logtable(:), rhoaxh2ovrhom_logtable_buff(:) !RL 112823
  public loga_table, phinorm_table, phidotnorm_table, phinorm_table_ddlga, phidotnorm_table_ddlga
  public rhoaxh2ovrhom_logtable, rhoaxh2ovrhom_logtable_buff !RL 112823 - replacing CP tables with public tables
  public aeq_LCDM !RL 031924


  !Decrease step sizes, etc. by this parameter. Useful for checking accuracy.
  !Can also be used to improve speed significantly if less accuracy is required.
  !or improving accuracy for extreme models.
  !Note this does not increase lSamp%l sampling or massive neutrino q-sampling

  real(sp) :: lAccuracyBoost=1.
  !Boost number of multipoles integrated in Boltzman heirarchy

  integer :: limber_phiphi = 0 !for l>limber_phiphi use limber approx for lensing potential
  integer :: num_redshiftwindows = 0
  integer :: num_extra_redshiftwindows = 0

  integer, parameter :: lmin = 2
  !must be either 1 or 2

  real(dl), parameter :: OmegaKFlat = 5e-7_dl !Value at which to use flat code

  real(dl),parameter :: tol=1.0d-4 !Base tolerance for integrations

  !     used as parameter for spline - tells it to use 'natural' end values
  real(dl), parameter :: spl_large=1.e40_dl

  integer, parameter:: l0max=4000

  !     lmax is max possible number of l's evaluated
  integer, parameter :: lmax_arr = l0max

  character(LEN=1024) :: highL_unlensed_cl_template = 'HighLExtrapTemplate_lenspotentialCls.dat'
  !fiducial high-accuracy high-L C_L used for making small cosmology-independent numerical corrections
  !to lensing and C_L interpolation. Ideally close to models of interest, but dependence is weak.
  logical :: use_spline_template = .true.
  integer, parameter :: lmax_extrap_highl = 8000
  real(dl), allocatable :: highL_CL_template(:,:)

  integer, parameter :: derived_age=1, derived_zstar=2, derived_rstar=3, derived_thetastar=4, derived_DAstar = 5, &
        derived_zdrag=6, derived_rdrag=7,derived_kD=8,derived_thetaD=9, derived_zEQ =10, derived_keq =11, &
        derived_thetaEQ=12, derived_theta_rs_EQ = 13
    integer, parameter :: nthermo_derived = 13

  real(dl) ThermoDerivedParams(nthermo_derived)

  Type TBackgroundOutputs
     real(dl), pointer :: z_outputs(:) => null()
     real(dl), allocatable :: H(:), DA(:), rs_by_D_v(:)
  end Type TBackgroundOutputs

  Type(TBackgroundOutputs), save :: BackgroundOutputs

contains


  subroutine CAMBParams_Set(P, error, DoReion)
    use constants
    type(CAMBparams), intent(in) :: P
    real(dl) fractional_number, conv !GetOmegak RL commented out 032724
    integer, optional :: error !Zero if OK
    logical, optional :: DoReion
    logical WantReion
    integer nu_i,actual_massless
    real(dl) neff_i
    !external GetOmegak
    real(dl), save :: last_tau0
    !Constants in SI units
    real clock_start, clock_stop ! RH timing
    integer :: i_check
    real(dl) dtauda
    external dtauda
    global_error_flag = 0

    call cpu_time(clock_start) ! RH timing  
    if ((P%WantTensors .or. P%WantVectors).and. P%WantTransfer .and. .not. P%WantScalars) then
       call GlobalError( 'Cannot generate tensor C_l and transfer without scalar C_l',error_unsupported_params)
    end if

    if (present(error)) error = global_error_flag
    if (global_error_flag/=0) return

    if (present(DoReion)) then
       WantReion = DoReion
    else
       WantReion = .true.
    end if

    CP=P
    if (call_again) CP%DerivedParameters = .false.

    CP%Max_eta_k = max(CP%Max_eta_k,CP%Max_eta_k_tensor)

    if (CP%WantTransfer) then
       CP%WantScalars=.true.
       if (.not. CP%WantCls) then
          CP%AccuratePolarization = .false.
          CP%Reion%Reionization = .false.
       end if
    else
       CP%transfer%num_redshifts=0
    end if
   
    if ((CP%WantTransfer).and. CP%MassiveNuMethod==Nu_approx) then
       CP%MassiveNuMethod = Nu_trunc
    end if

    !!write(*, *) 'CP%omegak before GetOmegak()', CP%omegak !RL 032724: CP%omegak is already assigned before GetOmegak(). Tested that in all cases the difference between these two results are very small (mostly 1e-16 level). Since GetOmegak() is physically wrong, I removed it and readjusted H0 instead, although in practice the effect is very small.
    !!CP%omegak = GetOmegak()
    !!write(*, *) 'CP%omegak after GetOmegak()', CP%omegak
    
    CP%flat = (abs(CP%omegak) <= OmegaKFlat)
    CP%closed = CP%omegak < -OmegaKFlat

    CP%open = .not.CP%flat.and..not.CP%closed
    if (CP%flat) then
       CP%curv=0
       CP%Ksign=0
       CP%r=1._dl !so we can use tau/CP%r, etc, where CP%r's cancel
    else
       CP%curv=-CP%omegak/((c/1000)/CP%h0)**2
       CP%Ksign =sign(1._dl,CP%curv)
       CP%r=1._dl/sqrt(abs(CP%curv))
    end if
    !  grho gives the contribution to the expansion rate from: (g) photons,
    !  (r) one flavor of relativistic neutrino (2 degrees of freedom),
    !  (m) nonrelativistic matter (for Omega=1).  grho is actually
    !  8*pi*G*rho/c^2 at a=1, with units of Mpc**(-2).
    !  a=tau(Mpc)*adotrad, with a=1 today, assuming 3 neutrinos.
    !  (Used only to set the initial conformal time.)

    !H0 is in km/s/Mpc

    grhom = 3*CP%h0**2/c**2*1000**2 !3*h0^2/c^2 (=8*pi*G*rho_crit/c^2)


    !grhom=3.3379d-11*h0*h0
    grhog = (kappa/c**2._dl)*4._dl*sigma_boltz/(c**3._dl)*(CP%tcmb**4._dl)*(Mpc**2._dl) !8*pi*G/c^2*4*sigma_B/c^3 T^4
    ! grhog=1.4952d-13*tcmb**4
    grhor = 7._dl/8._dl*(4._dl/11._dl)**(4._dl/3._dl)*grhog !7/8*(4/11)^(4/3)*grhog (per neutrino species)
    !grhor=3.3957d-14*tcmb**4

    !correction for fractional number of neutrinos, e.g. 3.04 to give slightly higher T_nu hence rhor
    !for massive Nu_mass_degeneracies parameters account for heating from grhor

    grhornomass=grhor*CP%Nu_massless_degeneracy !RL fixed 020625
    grhormass=0
    do nu_i = 1, CP%Nu_mass_eigenstates
       grhormass(nu_i)=grhor*CP%Nu_mass_degeneracies(nu_i)
    end do

    grhoc=grhom*CP%omegac


    grhob=grhom*CP%omegab !fractional difference changes from -8.243792823000173E-002 to -1.092318371998413E-003

    grhov=grhom*CP%omegav !fractional difference changes from -1.092318371998413E-003 to 0
    grhok=grhom*CP%omegak

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Axions 
    grhoax=grhom*CP%omegaax
    a_osc=CP%a_osc
    ! DM: Set a_osc=1 in case scalar field crashes for bad cosmology
    if(a_osc>1) then 
       a_osc=1.
    end if
    


    !  adotrad gives the relation a(tau) in the radiation era:
    adotrad = sqrt((grhog+grhornomass+sum(grhormass(1:CP%Nu_mass_eigenstates)))/3)


    Nnow = CP%omegab*(1-CP%yhe)*grhom*c**2/kappa/m_H/Mpc**2

    akthom = sigma_thomson*Nnow*Mpc
    !sigma_T * (number density of protons now)

    fHe = CP%YHe/(mass_ratio_He_H*(1.d0-CP%YHe))  !n_He_tot / n_H_tot

    if (.not.call_again) then
       !call init_massive_nu(CP%omegan /=0) !RL commnented out 07/10/23
       call init_background
       if (global_error_flag==0) then
          ! print *, 'chi = ',  (CP%tau0 - TimeOfz(0.15_dl)) * CP%h0/100
          last_tau0=CP%tau0
          if (WantReion) call Reionization_Init(CP%Reion,CP%ReionHist, CP%YHe, akthom, CP%tau0, FeedbackLevel)
       end if
    else
       CP%tau0=last_tau0
    end if

    !JD 08/13 Changes for nonlinear lensing of CMB + MPK compatibility
    !if ( CP%NonLinear==NonLinear_Lens) then
    if (CP%NonLinear==NonLinear_Lens .or. CP%NonLinear==NonLinear_both ) then
       CP%Transfer%kmax = max(CP%Transfer%kmax, CP%Max_eta_k/CP%tau0)
       if (FeedbackLevel > 0 .and. CP%Transfer%kmax== CP%Max_eta_k/CP%tau0) &
            write (*,*) 'max_eta_k changed to ', CP%Max_eta_k
    end if

    if (CP%closed .and. CP%tau0/CP%r >3.14) then
       call GlobalError('chi >= pi in closed model not supported',error_unsupported_params)
    end if

    if (global_error_flag/=0) then
       if (present(error)) error = global_error_flag
       return
    end if

    ! RH made the change as requested by the OxFish readme file
    !    open(unit=66,file="/Users/reneehlozek/Code/OxFishDec15_axion/results/thetaMC.dat",status='replace')
    !    write(66,'(f10.8)') 100*CosmomcTheta()
    !    close(unit=66) 


    if (present(error)) then
       error = 0
    else if (FeedbackLevel > 0 .and. .not. call_again) then
       write(*,'("Om_b h^2             = ",f9.6)') CP%omegab*(CP%H0/100)**2
       write(*,'("Om_c h^2             = ",f9.6)') CP%omegac*(CP%H0/100)**2
       write(*,'("Om_nu h^2            = ",f9.6)') CP%omegan*(CP%H0/100)**2
       write(*,'("Om_Lambda            = ",f9.6)') CP%omegav
       write(*,'("H0                   = ",f10.6)') CP%H0
       !Axions                                                                                                                    
       write(*,'("Om_ax h^2            = ",f9.6)') CP%omegaax*(CP%H0/100)**2
       !write(*,'("a_osc                = ",e9.2)')  a_osc
       !write(*,'("tau_osc/Mpc          = ",f9.3)') CP%tau_osc


!!!!!!!!
!!!DG: a_eq output suppressed. See explanation for why z_EQ output also suppressed
       !!        write(*,'("a_eq               = ",e9.2)')  CP%aeq
!!!!!!!!!!!!!!!!!!!!!!!!



       write(*,'("m_ax/eV              = ",e9.2)')  CP%ma !!/(100/.3e5)

       !DG 5/25/2015 Use updated omegak that includes massless and massive neutrinos self consistently
       !correction in the 5th decimal place but now completely includes this
       write(*,'("Om_K                 = ",f9.6)') CP%omegak
       write(*,'("Om_m (1-Om_K-Om_L)   = ",f9.6)') 1-CP%omegak-CP%omegav
       write(*,'("100 theta (CosmoMC)  = ",f9.6)') 100*CosmomcTheta()

       if (CP%Num_Nu_Massive > 0) then
          write(*,'("N_eff (total)        = ",f9.6)') CP%Nu_massless_degeneracy + &
               sum(CP%Nu_mass_degeneracies(1:CP%Nu_mass_eigenstates))
          do nu_i=1, CP%Nu_mass_eigenstates
             conv = k_B*(8*grhor/grhog/7)**0.25*CP%tcmb/elecV * &
                  (CP%nu_mass_degeneracies(nu_i)/CP%nu_mass_numbers(nu_i))**0.25 !approx 1.68e-4 !! changing eV to elecV
             write(*,'(I2, " nu, g=",f7.4," m_nu*c^2/k_B/T_nu0= ",f9.2," (m_nu= ",f6.3," eV)")') &
                  CP%nu_mass_numbers(nu_i), CP%nu_mass_degeneracies(nu_i), nu_masses(nu_i),conv*nu_masses(nu_i)
          end do
       end if
    end if
    CP%chi0=rofChi(CP%tau0/CP%r)
    scale= CP%chi0*CP%r/CP%tau0  !e.g. change l sampling depending on approx peak spacing

    !    call cpu_time(clock_stop) ! RH timing                                                        
    !    print*, 'Total time taken RH in CAMBParams_Set:', clock_stop - clock_start
  end subroutine CAMBParams_Set


  function GetTestTime()
    real(sp) GetTestTime
    real(sp) atime

    !           GetTestTime = etime(tarray)
    !Can replace this if etime gives problems
    !Or just comment out - only used if DebugMsgs = .true.
    call cpu_time(atime)
    GetTestTime = atime

  end function GetTestTime


  function rofChi(Chi) !sinh(chi) for open, sin(chi) for closed.
    real(dl) Chi,rofChi

    if (CP%closed) then
       rofChi=sin(chi)
    else if (CP%open) then
       rofChi=sinh(chi)
    else
       rofChi=chi
    endif
  end function rofChi


  function cosfunc (Chi)
    real(dl) Chi,cosfunc

    if (CP%closed) then
       cosfunc= cos(chi)
    else if (CP%open) then
       cosfunc=cosh(chi)
    else
       cosfunc = 1._dl
    endif
  end function cosfunc

  function tanfunc(Chi)
    real(dl) Chi,tanfunc
    if (CP%closed) then
       tanfunc=tan(Chi)
    else if (CP%open) then
       tanfunc=tanh(Chi)
    else
       tanfunc=Chi
    end if

  end  function tanfunc

  function invsinfunc(x)
    real(dl) invsinfunc,x

    if (CP%closed) then
       invsinfunc=asin(x)
    else if (CP%open) then
       invsinfunc=log((x+sqrt(1._dl+x**2)))
    else
       invsinfunc = x
    endif
  end function invsinfunc

  function f_K(x)
    real(dl) :: f_K
    real(dl), intent(in) :: x
    f_K = CP%r*rofChi(x/CP%r)

  end function f_K


  function DeltaTime(a1,a2, in_tol)
    implicit none
    real(dl) DeltaTime, atol
    real(dl), intent(IN) :: a1,a2
    real(dl), optional, intent(in) :: in_tol
    real(dl) dtauda, rombint !diff of tau w.CP%r.t a and integration
    external dtauda, rombint


    if (present(in_tol)) then
       atol = in_tol
    else
       atol = tol/1000/exp(AccuracyBoost-1)
    end if

    !RL modified for ULA switch
    if (a1 .lt. CP%a_osc .and. a2 .ge. CP%a_osc) then
       !!write(*, *) 'Rayne, a1 and a2 straddles aosc'
       !DeltaTime=rombint(dtauda,a1,CP%a_osc,atol) + rombint(dtauda, CP%a_osc*(1._dl+max(atol/100.0_dl,1.d-15)), a2, atol)
       DeltaTime=rombint(dtauda,a1,CP%a_osc*(1._dl-max(atol/100.0_dl,1.d-15)),atol) + rombint(dtauda, CP%a_osc, a2, atol)
    else
       !!write(*, *) 'Rayne, a1 and a2 doesn''t straddle aosc'
       DeltaTime=rombint(dtauda,a1,a2,atol)
    end if

  end function DeltaTime

  function TimeOfz(z)
    implicit none
    real(dl) TimeOfz
    real(dl), intent(IN) :: z

    TimeOfz=DeltaTime(0._dl,1._dl/(z+1._dl)) 

  end function TimeOfz

  function DeltaPhysicalTimeGyr(a1,a2, in_tol)
    use constants
    real(dl), intent(in) :: a1, a2
    real(dl), optional, intent(in) :: in_tol
    real(dl) rombint,DeltaPhysicalTimeGyr, atol
    external rombint

    if (present(in_tol)) then
       atol = in_tol
    else
       atol = 1d-4/exp(AccuracyBoost-1)
    end if
    DeltaPhysicalTimeGyr = rombint(dtda,a1,a2,atol)*Mpc/c/Gyr
  end function DeltaPhysicalTimeGyr

  function AngularDiameterDistance(z)
    !This is the physical (non-comoving) angular diameter distance in Mpc
    real(dl) AngularDiameterDistance
    real(dl), intent(in) :: z

    AngularDiameterDistance = CP%r/(1+z)*rofchi(ComovingRadialDistance(z) /CP%r)

  end function AngularDiameterDistance

  function LuminosityDistance(z)
    real(dl) LuminosityDistance
    real(dl), intent(in) :: z

    LuminosityDistance = AngularDiameterDistance(z)*(1+z)**2

  end function LuminosityDistance

  function ComovingRadialDistance(z)
    real(dl) ComovingRadialDistance
    real(dl), intent(in) :: z

    ComovingRadialDistance = DeltaTime(1/(1+z),1._dl, 1.d-7) !RL reverted 062624 since thetastar may have a problem there !RL modified the tolerance here to 1.e-6 or else the code crashes for some axion masses

  end function ComovingRadialDistance

  function Hofz(z)
    !!non-comoving Hubble in MPC units, divide by MPC_in_sec to get in SI units
    real(dl) Hofz, dtauda,a
    real(dl), intent(in) :: z
    external dtauda

    a = 1/(1+z)
    Hofz = 1/(a**2*dtauda(a))

  end function Hofz

  real(dl) function BAO_D_v_from_DA_H(z, DA, Hz)
    real(dl), intent(in) :: z, DA, Hz
    real(dl) ADD

    ADD = DA*(1.d0+z)
    BAO_D_v_from_DA_H = ((ADD)**2.d0*z/Hz)**(1.d0/3.d0)

  end function BAO_D_v_from_DA_H

  real(dl) function BAO_D_v(z)
    real(dl), intent(IN) :: z

    BAO_D_v = BAO_D_v_from_DA_H(z,AngularDiameterDistance(z), Hofz(z))

  end function BAO_D_v

  function dsound_da_exact(a)
    implicit none
    real(dl) dsound_da_exact,dtauda,a,R,cs
    external dtauda

    R = 3*grhob*a / (4*grhog)
    cs=1.0d0/sqrt(3*(1+R))
    dsound_da_exact=dtauda(a)*cs

  end function dsound_da_exact


  function dsound_da(a)
    !approximate form used e.g. by CosmoMC for theta
    implicit none
    real(dl) dsound_da,dtauda,a,R,cs
    external dtauda

    R=3.0d4*a*CP%omegab*(CP%h0/100.0d0)**2
    !          R = 3*grhob*a / (4*grhog) //above is mostly within 0.2% and used for previous consistency
    cs=1.0d0/sqrt(3*(1+R))
    dsound_da=dtauda(a)*cs

  end function dsound_da

  function dtda(a)
    real(dl) dtda,dtauda,a
    external dtauda
    dtda= dtauda(a)*a
  end function dtda

  function CosmomcTheta()
    real(dl) zstar, astar, atol, rs, DA
    real(dl) CosmomcTheta
    real(dl) ombh2, omdmh2
    real(dl) rombint
    external rombint

    ombh2 = CP%omegab*(CP%h0/100.0d0)**2
    !Added ultra-light axions to computation of Hu + Sugiyama Theta_MC
    !used to step around chains
    !Actually not a physsical parameter (theta_mc)
    !But useful stepping parameter
    omdmh2 = (CP%omegac+CP%omegan+CP%omegaax)*(CP%h0/100.0d0)**2! RH axion   

    !    omdmh2 = (CP%omegac+CP%omegan)*(CP%h0/100.0d0)**2
    !!From Hu & Sugiyama
    ! Appendix E of astro-ph/9510117

    zstar =  1048*(1+0.00124*ombh2**(-0.738))* &
         (1+(0.0783*ombh2**(-0.238)/(1+39.5*ombh2**0.763))&
         *(omdmh2+ombh2)**(0.560/(1+21.1*ombh2**1.81)))

    astar = 1/(1+zstar)
    atol = 1e-6
    rs = rombint(dsound_da,1d-8,astar,atol)
    DA = AngularDiameterDistance(zstar)/astar
    CosmomcTheta = rs/DA

  end function CosmomcTheta



end module ModelParams



!ccccccccccccccccccccccccccccccccccccccccccccccccccc

module lvalues
  use precision
  use ModelParams
  implicit none
  public

  Type lSamples
     integer l0
     integer l(lmax_arr)
  end Type lSamples

  Type(lSamples) :: lSamp
  !Sources
  logical :: Log_lvalues  = .false.

contains

  function lvalues_indexOf(lSet,l)
    type(lSamples) :: lSet
    integer, intent(in) :: l
    integer lvalues_indexOf, i

    do i=2,lSet%l0
       if (l < lSet%l(i)) then
          lvalues_indexOf = i-1
          return
       end if
    end do
    lvalues_indexOf = lSet%l0

  end function  lvalues_indexOf

  subroutine initlval(lSet,max_l)

    ! This subroutines initializes lSet%l arrays. Other values will be interpolated.

    implicit none
    type(lSamples) :: lSet

    integer, intent(IN) :: max_l
    integer lind, lvar, step,top,bot,ls(lmax_arr)
    real(dl) AScale

    Ascale=scale/lSampleBoost

    if (lSampleBoost >=50) then
       !just do all of them
       lind=0
       do lvar=lmin, max_l
          lind=lind+1
          ls(lind)=lvar
       end do
       lSet%l0=lind
       lSet%l(1:lind) = ls(1:lind)
       return
    end if

    lind=0
    do lvar=lmin, 10
       lind=lind+1
       ls(lind)=lvar
    end do

    if (CP%AccurateReionization) then
       if (lSampleBoost > 1) then
          do lvar=11, 37,1
             lind=lind+1
             ls(lind)=lvar
          end do
       else
          do lvar=11, 37,2
             lind=lind+1
             ls(lind)=lvar
          end do
       end if

       step = max(nint(5*Ascale),2)
       bot=40
       top=bot + step*10
    else
       if (lSampleBoost >1) then
          do lvar=11, 15
             lind=lind+1
             ls(lind)=lvar
          end do
       else
          lind=lind+1
          ls(lind)=12
          lind=lind+1
          ls(lind)=15
       end if
       step = max(nint(10*Ascale),3)
       bot=15+max(step/2,2)
       top=bot + step*7
    end if

    do lvar=bot, top, step
       lind=lind+1
       ls(lind)=lvar
    end do

    !Sources
    if (Log_lvalues) then
       !Useful for generating smooth things like 21cm to high l
       step=max(nint(20*Ascale),4)
       do
          lvar = lvar + step
          if (lvar > max_l) exit
          lind=lind+1
          ls(lind)=lvar
          step = nint(step*1.2) !log spacing
       end do
    else
       step=max(nint(20*Ascale),4)
       bot=ls(lind)+step
       top=bot+step*2

       do lvar = bot,top,step
          lind=lind+1
          ls(lind)=lvar
       end do

       if (ls(lind)>=max_l) then
          do lvar=lind,1,-1
             if (ls(lvar)<=max_l) exit
          end do
          lind=lvar
          if (ls(lind)<max_l) then
             lind=lind+1
             ls(lind)=max_l
          end if
       else
          step=max(nint(25*Ascale),4)
          !Get EE right around l=200 by putting extra point at 175
          bot=ls(lind)+step
          top=bot+step

          do lvar = bot,top,step
             lind=lind+1
             ls(lind)=lvar
          end do

          if (ls(lind)>=max_l) then
             do lvar=lind,1,-1
                if (ls(lvar)<=max_l) exit
             end do
             lind=lvar
             if (ls(lind)<max_l) then
                lind=lind+1
                ls(lind)=max_l
             end if
          else
             if (HighAccuracyDefault .and. .not. use_spline_template) then
                step=max(nint(42*Ascale),7)
             else
                step=max(nint(50*Ascale),7)
             end if
             bot=ls(lind)+step
             top=min(5000,max_l)

             do lvar = bot,top,step
                lind=lind+1
                ls(lind)=lvar
             end do

             if (max_l > 5000) then
                !Should be pretty smooth or tiny out here
                step=max(nint(400*Ascale),50)
                lvar = ls(lind)
                do
                   lvar = lvar + step
                   if (lvar > max_l) exit
                   lind=lind+1
                   ls(lind)=lvar
                   step = nint(step*1.5) !log spacing
                end do
             end if
             !Sources
          end if !log_lvalues

          if (ls(lind) /=max_l) then
             lind=lind+1
             ls(lind)=max_l
          end if
          if (.not. CP%flat) ls(lind-1)=int(max_l+ls(lind-2))/2
          !Not in CP%flat case so interpolation table is the same when using lower l_max
       end if
    end if
    lSet%l0=lind
    lSet%l(1:lind) = ls(1:lind)

  end subroutine initlval

  subroutine InterpolateClArr(lSet,iCl, all_Cl, max_ind)
    type (lSamples), intent(in) :: lSet
    real(dl), intent(in) :: iCl(*)
    real(dl), intent(out):: all_Cl(lmin:*)
    integer, intent(in) :: max_ind
    integer il,llo,lhi, xi
    real(dl) ddCl(lSet%l0)
    real(dl) xl(lSet%l0)

    real(dl) a0,b0,ho
    real(dl), parameter :: cllo=1.e30_dl,clhi=1.e30_dl
    !    real clock_start, clock_stop ! RH timing

    !    call cpu_time(clock_start) ! RH timing 
    if (max_ind > lSet%l0) stop 'Wrong max_ind in InterpolateClArr'

    xl = real(lSet%l(1:lSet%l0),dl)
    call spline(xl,iCL(1),max_ind,cllo,clhi,ddCl(1))

    llo=1
    do il=lmin,lSet%l(max_ind)
       xi=il
       if ((xi > lSet%l(llo+1)).and.(llo < max_ind)) then
          llo=llo+1
       end if
       lhi=llo+1
       ho=lSet%l(lhi)-lSet%l(llo)
       a0=(lSet%l(lhi)-xi)/ho
       b0=(xi-lSet%l(llo))/ho

       all_Cl(il) = a0*iCl(llo)+ b0*iCl(lhi)+((a0**3-a0)* ddCl(llo) &
            +(b0**3-b0)*ddCl(lhi))*ho**2/6
    end do

    !    call cpu_time(clock_stop) ! RH timing                                                        
    !    print*, 'Total time taken RH in InterpolateClArr:', clock_stop - clock_start
  end subroutine InterpolateClArr

  subroutine InterpolateClArrTemplated(lSet,iCl, all_Cl, max_ind, template_index)
    type (lSamples), intent(in) :: lSet
    real(dl), intent(in) :: iCl(*)
    real(dl), intent(out):: all_Cl(lmin:*)
    integer, intent(in) :: max_ind
    integer, intent(in), optional :: template_index
    integer maxdelta, il
    real(dl) DeltaCL(lSet%l0)
    real(dl), allocatable :: tmpall(:)
    real clock_start, clock_stop ! RH timing 

    call cpu_time(clock_start) ! RH timing
    if (max_ind > lSet%l0) stop 'Wrong max_ind in InterpolateClArrTemplated'

    if (use_spline_template .and. present(template_index)) then
       if (template_index<=3) then
          !interpolate only the difference between the C_l and an accurately interpolated template. Temp only for the mo.
          !Using unlensed for template, seems to be good enough
          maxdelta=max_ind
          do while (lSet%l(maxdelta) > lmax_extrap_highl)
             maxdelta=maxdelta-1
          end do
          DeltaCL(1:maxdelta)=iCL(1:maxdelta)- highL_CL_template(lSet%l(1:maxdelta), template_index)

          call InterpolateClArr(lSet,DeltaCl, all_Cl, maxdelta)

          do il=lmin,lSet%l(maxdelta)
             all_Cl(il) = all_Cl(il) +  highL_CL_template(il,template_index)
          end do

          if (maxdelta < max_ind) then
             !directly interpolate high L where no template (doesn't effect lensing spectrum much anyway)
             allocate(tmpall(lmin:lSet%l(max_ind)))
             call InterpolateClArr(lSet,iCl, tmpall, max_ind)
             !overlap to reduce interpolation artefacts
             all_cl(lSet%l(maxdelta-2):lSet%l(max_ind) ) = tmpall(lSet%l(maxdelta-2):lSet%l(max_ind))
             deallocate(tmpall)
          end if
          return
       end if
    end if

    call InterpolateClArr(lSet,iCl, all_Cl, max_ind)

    call cpu_time(clock_stop) ! RH timing 
    !    print*, 'Total time taken RH in InterpolateClArrTemplated:', clock_stop - clock_start 

  end subroutine InterpolateClArrTemplated

end module lvalues


!ccccccccccccccccccccccccccccccccccccccccccccccccccc

module ModelData
  use precision
  use ModelParams
  use InitialPower
  use lValues
  use Ranges
  use AMlUtils
  implicit none
  public

  Type LimberRec
     integer n1,n2 !corresponding time step array indices
     real(dl), dimension(:), pointer :: k
     real(dl), dimension(:), pointer :: Source
  end Type LimberRec

  Type ClTransferData
     !Cl transfer function variables
     !values of q for integration over q to get C_ls
     Type (lSamples) :: ls ! scalar and tensor l that are computed
     integer :: NumSources
     !Changes -scalars:  2 for just CMB, 3 for lensing
     !- tensors: T and E and phi (for lensing), and T, E, B respectively

     Type (Regions) :: q
     real(dl), dimension(:,:,:), pointer :: Delta_p_l_k => NULL()

     !The L index of the lowest L to use for Limber
     integer, dimension(:), pointer :: Limber_l_min => NULL()
     !For each l, the set of k in each limber window
     !indices LimberWindow(SourceNum,l)
     Type(LimberRec), dimension(:,:), pointer :: Limber_windows => NULL()

     !The maximum L needed for non-Limber
     integer max_index_nonlimber

  end Type ClTransferData

  Type(ClTransferData), save, target :: CTransScal, CTransTens, CTransVec

  !Computed output power spectra data

  integer, parameter :: C_Temp = 1, C_E = 2, C_Cross =3, C_Phi = 4, C_PhiTemp = 5, C_PhiE=6
  integer :: C_last = C_PhiE
  integer, parameter :: CT_Temp =1, CT_E = 2, CT_B = 3, CT_Cross=  4

  logical :: has_cl_2D_array = .false.

  real(dl), dimension (:,:,:), allocatable :: Cl_scalar, Cl_tensor, Cl_vector
  !Indices are Cl_xxx( l , intial_power_index, Cl_type)
  !where Cl_type is one of the above constants

  real(dl), dimension (:,:,:,:), allocatable :: Cl_Scalar_Array
  !Indices are Cl_xxx( l , intial_power_index, field1,field2)
  !where ordering of fields is T, E, \psi (CMB lensing potential), window_1, window_2...

  !The following are set only if doing lensing
  integer lmax_lensed !Only accurate to rather less than this
  real(dl) , dimension (:,:,:), allocatable :: Cl_lensed
  !Cl_lensed(l, power_index, Cl_type) are the interpolated Cls

contains

  subroutine Init_ClTransfer(CTrans)
    !Need to set the Ranges array q before calling this
    Type(ClTransferData) :: CTrans
    integer st

    deallocate(CTrans%Delta_p_l_k, STAT = st)
    call Ranges_getArray(CTrans%q, .true.)

    allocate(CTrans%Delta_p_l_k(CTrans%NumSources,min(CTrans%max_index_nonlimber,CTrans%ls%l0), CTrans%q%npoints))
    CTrans%Delta_p_l_k = 0

  end subroutine Init_ClTransfer

  subroutine Init_Limber(CTrans)
    Type(ClTransferData) :: CTrans

    allocate(CTrans%Limber_l_min(CTrans%NumSources))
    CTrans%Limber_l_min = 0
    if (num_redshiftwindows>0 .or. limber_phiphi>0) then
       allocate(CTrans%Limber_windows(CTrans%NumSources,CTrans%ls%l0))
    end if

  end subroutine Init_Limber

  subroutine Free_ClTransfer(CTrans)
    Type(ClTransferData) :: CTrans
    integer st

    deallocate(CTrans%Delta_p_l_k, STAT = st)
    nullify(CTrans%Delta_p_l_k)
    call Ranges_Free(CTrans%q)
    call Free_Limber(CTrans)

  end subroutine Free_ClTransfer

  subroutine Free_Limber(CTrans)
    Type(ClTransferData) :: CTrans
    integer st,i,j

    if (associated(CTrans%Limber_l_min)) then
       do i=1, CTrans%NumSources
          if (CTrans%Limber_l_min(i)/=0) then
             do j=CTrans%Limber_l_min(i), CTrans%ls%l0
                deallocate(CTrans%Limber_windows(i, j)%k, STAT = st)
                deallocate(CTrans%Limber_windows(i, j)%Source, STAT = st)
             end do
          end if
       end do
       deallocate(CTrans%Limber_l_min, STAT = st)
    end if
    deallocate(CTrans%Limber_windows, STAT = st)
    nullify(CTrans%Limber_l_min)
    nullify(CTrans%Limber_windows)

  end subroutine Free_Limber

  subroutine CheckLoadedHighLTemplate
    integer L
    real(dl) array(7)

    if (.not. allocated(highL_CL_template)) then
       allocate(highL_CL_template(lmin:lmax_extrap_highl, C_Temp:C_Phi))
       call OpenTxtFile(highL_unlensed_cl_template,fileio_unit)
       if (lmin==1) highL_CL_template(lmin,:)=0
       do
          read(fileio_unit,*, end=500) L , array
          if (L>lmax_extrap_highl) exit
          !  array = array * (2*l+1)/(4*pi) * 2*pi/(l*(l+1))
          highL_CL_template(L, C_Temp:C_E) =array(1:2)
          highL_CL_template(L, C_Cross) =array(4)
          highL_CL_template(L, C_Phi) =array(5)
       end do

500    if (L< lmax_extrap_highl) &
            stop 'CheckLoadedHighLTemplate: template file does not go up to lmax_extrap_highl'
       close(fileio_unit)
    end if

  end subroutine CheckLoadedHighLTemplate


  subroutine Init_Cls

    call CheckLoadedHighLTemplate
    if (CP%WantScalars) then
       if (allocated(Cl_scalar)) deallocate(Cl_scalar)
       allocate(Cl_scalar(lmin:CP%Max_l, CP%InitPower%nn, C_Temp:C_last))
       Cl_scalar = 0
       if (has_cl_2D_array) then
          if (allocated(Cl_scalar_array)) deallocate(Cl_scalar_array)
          allocate(Cl_scalar_Array(lmin:CP%Max_l, CP%InitPower%nn, 3+num_redshiftwindows,3+num_redshiftwindows))
          Cl_scalar_array = 0
       end if
    end if

    if (CP%WantVectors) then
       if (allocated(Cl_vector)) deallocate(Cl_vector)
       allocate(Cl_vector(lmin:CP%Max_l, CP%InitPower%nn, CT_Temp:CT_Cross))
       Cl_vector = 0
    end if


    if (CP%WantTensors) then
       if (allocated(Cl_tensor)) deallocate(Cl_tensor)
       allocate(Cl_tensor(lmin:CP%Max_l_tensor, CP%InitPower%nn, CT_Temp:CT_Cross))
       Cl_tensor = 0
    end if

  end subroutine Init_Cls

  subroutine output_cl_files(ScalFile,ScalCovFile,TensFile, TotFile, LensFile, LensTotFile, factor)
    implicit none
    integer in,il
    character(LEN=*) ScalFile, TensFile, TotFile, LensFile, LensTotFile,ScalCovfile
    real(dl), intent(in), optional :: factor
    real(dl) fact
    integer last_C
    real(dl), allocatable :: outarr(:,:)


    if (present(factor)) then
       fact = factor
    else
       fact =1
    end if

    if (CP%WantScalars .and. ScalFile /= '') then
       last_C=min(C_PhiTemp,C_last)
       open(unit=fileio_unit,file=ScalFile,form='formatted',status='replace')
       do in=1,CP%InitPower%nn
          do il=lmin,min(10000,CP%Max_l)
             write(fileio_unit,trim(numcat('(1I6,',last_C))//'E15.5)')il ,fact*Cl_scalar(il,in,C_Temp:last_C) !Default
             
             !RL 07282023 for full digit output, remove after testing is done
             !!!write(fileio_unit,trim(numcat('(1I6,',last_C))//'36e52.42)')il ,fact*Cl_scalar(il,in,C_Temp:last_C)
          end do
          do il=10100,CP%Max_l, 100
             write(fileio_unit,trim(numcat('(1E15.5,',last_C))//'E15.5)') real(il),&
                  fact*Cl_scalar(il,in,C_Temp:last_C) !Default
             
             !RL 07282023 for full digit output, remove after testing is done
             !!!write(fileio_unit,trim(numcat('(1E15.5,',last_C))//'36e52.42)') real(il),&
             !!!     fact*Cl_scalar(il,in,C_Temp:last_C)
          end do
       end do
       close(fileio_unit)
    end if

    if (CP%WantScalars .and. has_cl_2D_array .and. ScalCovFile /= '' .and. CTransScal%NumSources>2) then
       allocate(outarr(1:3+num_redshiftwindows,1:3+num_redshiftwindows))
       open(unit=fileio_unit,file=ScalCovFile,form='formatted',status='replace')
       do in=1,CP%InitPower%nn
          do il=lmin,min(10000,CP%Max_l)
             outarr=Cl_scalar_array(il,in,1:3+num_redshiftwindows,1:3+num_redshiftwindows)
             outarr(1:2,:)=sqrt(fact)*outarr(1:2,:)
             outarr(:,1:2)=sqrt(fact)*outarr(:,1:2)
             !RL 07282023 for full digit output, remove after testing is done
             write(fileio_unit,trim(numcat('(1I6,',(3+num_redshiftwindows)**2))//'E15.5)') il, outarr
             !!!write(fileio_unit,trim(numcat('(1I6,',(3+num_redshiftwindows)**2))//'36e52.42)') il, outarr
          end do
          do il=10100,CP%Max_l, 100
             outarr=Cl_scalar_array(il,in,1:3+num_redshiftwindows,1:3+num_redshiftwindows)
             outarr(1:2,:)=sqrt(fact)*outarr(1:2,:)
             outarr(:,1:2)=sqrt(fact)*outarr(:,1:2)
             !RL 07282023 for full digit output, remove after testing is done
             write(fileio_unit,trim(numcat('(1E15.5,',(3+num_redshiftwindows)**2))//'E15.5)') real(il), outarr
             !!!write(fileio_unit,trim(numcat('(1E15.5,',(3+num_redshiftwindows)**2))//'36e52.42)') real(il), outarr
          end do
       end do
       close(fileio_unit)
       deallocate(outarr)
    end if

    if (CP%WantTensors .and. TensFile /= '') then
       open(unit=fileio_unit,file=TensFile,form='formatted',status='replace')
       do in=1,CP%InitPower%nn
          do il=lmin,CP%Max_l_tensor
             write(fileio_unit,'(1I6,4E15.5)')il, fact*Cl_tensor(il, in, CT_Temp:CT_Cross)
          end do
       end do
       close(fileio_unit)
    end if

    if (CP%WantTensors .and. CP%WantScalars .and. TotFile /= '') then
       open(unit=fileio_unit,file=TotFile,form='formatted',status='replace')
       do in=1,CP%InitPower%nn
          do il=lmin,CP%Max_l_tensor
             write(fileio_unit,'(1I6,4E15.5)')il, fact*(Cl_scalar(il, in, C_Temp:C_E)+ Cl_tensor(il,in, C_Temp:C_E)), &
                  fact*Cl_tensor(il,in, CT_B), fact*(Cl_scalar(il, in, C_Cross) + Cl_tensor(il, in, CT_Cross))
          end do
          do il=CP%Max_l_tensor+1,CP%Max_l
             write(fileio_unit,'(1I6,4E15.5)')il ,fact*Cl_scalar(il,in,C_Temp:C_E), 0._dl, fact*Cl_scalar(il,in,C_Cross)
          end do
       end do
       close(fileio_unit)
    end if

    if (CP%WantScalars .and. CP%DoLensing .and. LensFile /= '') then
       open(unit=fileio_unit,file=LensFile,form='formatted',status='replace')
       do in=1,CP%InitPower%nn
          do il=lmin, lmax_lensed
             write(fileio_unit,'(1I6,4E15.5)')il, fact*Cl_lensed(il, in, CT_Temp:CT_Cross)
             !RL 07282023 for full digit output, remove after testing is done
             !!!write(fileio_unit,'(1I6, 36e52.42)')il, fact*Cl_lensed(il, in, CT_Temp:CT_Cross)
          end do
       end do
       close(fileio_unit)
    end if


    if (CP%WantScalars .and. CP%WantTensors .and. CP%DoLensing .and. LensTotFile /= '') then
       open(unit=fileio_unit,file=LensTotFile,form='formatted',status='replace')
       do in=1,CP%InitPower%nn
          do il=lmin,min(CP%Max_l_tensor,lmax_lensed)
             write(fileio_unit,'(1I6,4E15.5)')il, fact*(Cl_lensed(il, in, CT_Temp:CT_Cross)+ Cl_tensor(il,in, CT_Temp:CT_Cross))
          end do
          do il=min(CP%Max_l_tensor,lmax_lensed)+1,lmax_lensed
             write(fileio_unit,'(1I6,4E15.5)')il, fact*Cl_lensed(il, in, CT_Temp:CT_Cross)
          end do
       end do
    end if
  end subroutine output_cl_files

  subroutine output_lens_pot_files(LensPotFile, factor)
    !Write out L TT EE BB TE PP PT PE where P is the lensing potential, all unlensed
    !This input supported by LensPix from 2010
    implicit none
    integer in,il
    real(dl), intent(in), optional :: factor
    real(dl) fact, scale, BB, TT, TE, EE
    character(LEN=*) LensPotFile
    !output file of dimensionless [l(l+1)]^2 C_phi_phi/2pi and [l(l+1)]^(3/2) C_phi_T/2pi
    !This is the format used by Planck_like but original LensPix uses scalar_output_file.

    !(Cl_scalar and scalar_output_file numbers are instead l^4 C_phi and l^3 C_phi
    ! - for historical reasons)

    if (present(factor)) then
       fact = factor
    else
       fact =1
    end if

    if (CP%WantScalars .and. CP%DoLensing .and. LensPotFile/='') then
       open(unit=fileio_unit,file=LensPotFile,form='formatted',status='replace')
       do in=1,CP%InitPower%nn
          do il=lmin,min(10000,CP%Max_l)
             TT = Cl_scalar(il, in, C_Temp)
             EE = Cl_scalar(il, in, C_E)
             TE = Cl_scalar(il, in, C_Cross)
             if (CP%WantTensors .and. il <= CP%Max_l_tensor) then
                TT= TT+Cl_tensor(il,in, CT_Temp)
                EE= EE+Cl_tensor(il,in, CT_E)
                TE= TE+Cl_tensor(il,in, CT_Cross)
                BB= Cl_tensor(il,in, CT_B)
             else
                BB=0
             end if
             scale = (real(il+1)/il)**2/OutputDenominator !Factor to go from old l^4 factor to new

             write(fileio_unit,'(1I6,7E15.5)') il , fact*TT, fact*EE, fact*BB, fact*TE, scale*Cl_scalar(il,in,C_Phi),&
                  (real(il+1)/il)**1.5/OutputDenominator*sqrt(fact)*Cl_scalar(il,in,C_PhiTemp:C_PhiE)
          end do
          do il=10100,CP%Max_l, 100
             scale = (real(il+1)/il)**2/OutputDenominator
             write(fileio_unit,'(1E15.5,7E15.5)') real(il), fact*Cl_scalar(il,in,C_Temp:C_E),0.,fact*Cl_scalar(il,in,C_Cross), &
                  scale*Cl_scalar(il,in,C_Phi),&
                  (real(il+1)/il)**1.5/OutputDenominator*sqrt(fact)*Cl_scalar(il,in,C_PhiTemp:C_PhiE)
          end do
       end do
       close(fileio_unit)
    end if
  end subroutine output_lens_pot_files


  subroutine output_veccl_files(VecFile, factor)
    implicit none
    integer in,il
    character(LEN=*) VecFile
    real(dl), intent(in), optional :: factor
    real(dl) fact


    if (present(factor)) then
       fact = factor
    else
       fact =1
    end if


    if (CP%WantVectors .and. VecFile /= '') then
       open(unit=fileio_unit,file=VecFile,form='formatted',status='replace')
       do in=1,CP%InitPower%nn
          do il=lmin,CP%Max_l
             write(fileio_unit,'(1I5,4E15.5)')il, fact*Cl_vector(il, in, CT_Temp:CT_Cross)
          end do
       end do

       close(fileio_unit)
    end if

  end subroutine output_veccl_files

  subroutine NormalizeClsAtL(lnorm)
    implicit none
    integer, intent(IN) :: lnorm
    integer in
    real(dl) Norm

    do in=1,CP%InitPower%nn
       if (CP%WantScalars) then
          Norm=1/Cl_scalar(lnorm,in, C_Temp)
          Cl_scalar(lmin:CP%Max_l, in, C_Temp:C_Cross) = Cl_scalar(lmin:CP%Max_l, in, C_Temp:C_Cross) * Norm
       end if

       if (CP%WantTensors) then
          if (.not.CP%WantScalars) Norm = 1/Cl_tensor(lnorm,in, C_Temp)
          !Otherwise Norm already set correctly
          Cl_tensor(lmin:CP%Max_l_tensor, in, CT_Temp:CT_Cross) =  &
               Cl_tensor(lmin:CP%Max_l_tensor, in, CT_Temp:CT_Cross) * Norm
       end if
    end do

  end  subroutine NormalizeClsAtL

  subroutine ModelData_Free

    call Free_ClTransfer(CTransScal)
    call Free_ClTransfer(CTransVec)
    call Free_ClTransfer(CTransTens)
    if (allocated(Cl_vector)) deallocate(Cl_vector)
    if (allocated(Cl_tensor)) deallocate(Cl_tensor)
    if (allocated(Cl_scalar)) deallocate(Cl_scalar)
    if (allocated(Cl_lensed)) deallocate(Cl_lensed)
    if (allocated(Cl_scalar_array)) deallocate(Cl_scalar_array)

  end subroutine ModelData_Free

end module ModelData


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
module MassiveNu
  use precision
  use ModelParams
  implicit none
  private

  real(dl), parameter  :: const  = 7._dl/120*pi**4 ! 5.68219698_dl
  !const = int q^3 F(q) dq = 7/120*pi^4
  real(dl), parameter  :: const2 = 5._dl/7/pi**2   !0.072372274_dl
  real(dl), parameter  :: zeta3  = 1.2020569031595942853997_dl
  real(dl), parameter  :: zeta5  = 1.0369277551433699263313_dl
  real(dl), parameter  :: zeta7  = 1.0083492773819228268397_dl

  integer, parameter  :: nrhopn=2000
  real(dl), parameter :: am_min = 0.01_dl  !0.02_dl
  !smallest a*m_nu to integrate distribution function rather than using series
  real(dl), parameter :: am_max = 600._dl
  !max a*m_nu to integrate

  real(dl),parameter  :: am_minp=am_min*1.1
  real(dl), parameter :: am_maxp=am_max*0.9

  real(dl) dlnam

  real(dl), dimension(:), allocatable ::  r1,p1,dr1,dp1,ddr1

  !Sample for massive neutrino momentum
  !These settings appear to be OK for P_k accuate at 1e-3 level
  integer, parameter :: nqmax0=80 !maximum array size of q momentum samples
  real(dl) :: nu_q(nqmax0), nu_int_kernel(nqmax0)

  integer nqmax !actual number of q modes evolves

  public const,Nu_Init,Nu_background, Nu_rho, Nu_drho,  nqmax0, nqmax, &
       nu_int_kernel, nu_q
contains
  !cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

  subroutine Nu_init

    !  Initialize interpolation tables for massive neutrinos.
    !  Use cubic splines interpolation of log rhonu and pnu vs. log a*m.

    integer i
    real(dl) dq,dlfdlq, q, am, rhonu,pnu
    real(dl) spline_data(nrhopn)

    !  nu_masses=m_nu(i)*c**2/(k_B*T_nu0).
    !  Get number density n of neutrinos from
    !  rho_massless/n = int q^3/(1+e^q) / int q^2/(1+e^q)=7/180 pi^4/Zeta(3)
    !  then m = Omega_nu/N_nu rho_crit /n
    !  Error due to velocity < 1e-5
    do i=1, CP%Nu_mass_eigenstates
       nu_masses(i)=const/(1.5d0*zeta3)*grhom/grhor*CP%omegan*CP%Nu_mass_fractions(i) &
            /CP%Nu_mass_degeneracies(i)
    end do

    if (allocated(r1)) return
    allocate(r1(nrhopn),p1(nrhopn),dr1(nrhopn),dp1(nrhopn),ddr1(nrhopn))


    nqmax=3
    if (AccuracyBoost >1) nqmax=4
    if (AccuracyBoost >2) nqmax=5
    if (AccuracyBoost >3) nqmax=nint(AccuracyBoost*10)
    !note this may well be worse than the 5 optimized points

    if (nqmax > nqmax0) call MpiStop('Nu_Init: qmax > nqmax0')

    !We evolve evolve 4F_l/dlfdlq(i), so kernel includes dlfdlnq factor
    !Integration scheme gets (Fermi-Dirac thing)*q^n exact,for n=-4, -2..2
    !see CAMB notes
    if (nqmax==3) then
       !Accurate at 2e-4 level
       nu_q(1:3) = (/0.913201, 3.37517, 7.79184/)
       nu_int_kernel(1:3) = (/0.0687359, 3.31435, 2.29911/)
    else if (nqmax==4) then
       !This seems to be very accurate (limited by other numerics)
       nu_q(1:4) = (/0.7, 2.62814, 5.90428, 12.0/)
       nu_int_kernel(1:4) = (/0.0200251, 1.84539, 3.52736, 0.289427/)
    else if (nqmax==5) then
       !exact for n=-4,-2..3
       !This seems to be very accurate (limited by other numerics)
       nu_q(1:5) = (/0.583165, 2.0, 4.0, 7.26582, 13.0/)
       nu_int_kernel(1:5) = (/0.0081201, 0.689407, 2.8063, 2.05156, 0.126817/)
    else
       dq = (12 + nqmax/5)/real(nqmax)
       do i=1,nqmax
          q=(i-0.5d0)*dq
          nu_q(i) = q
          dlfdlq=-q/(1._dl+exp(-q))
          nu_int_kernel(i)=dq*q**3/(exp(q)+1._dl) * (-0.25_dl*dlfdlq) !now evolve 4F_l/dlfdlq(i)
       end do
    end if
    nu_int_kernel=nu_int_kernel/const

    dlnam=-(log(am_min/am_max))/(nrhopn-1)


    !$OMP PARALLEL DO DEFAULT(SHARED),SCHEDULE(STATIC) &
    !$OMP & PRIVATE(am, rhonu,pnu)
    do i=1,nrhopn
       am=am_min*exp((i-1)*dlnam)
       call nuRhoPres(am,rhonu,pnu)
       r1(i)=log(rhonu)
       p1(i)=log(pnu)
    end do
    !$OMP END PARALLEL DO


    call splini(spline_data,nrhopn)
    call splder(r1,dr1,nrhopn,spline_data)
    call splder(p1,dp1,nrhopn,spline_data)
    call splder(dr1,ddr1,nrhopn,spline_data)


  end subroutine Nu_init

  !cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  subroutine nuRhoPres(am,rhonu,pnu)
    !  Compute the density and pressure of one eigenstate of massive neutrinos,
    !  in units of the mean density of one flavor of massless neutrinos.

    real(dl),  parameter :: qmax=30._dl
    integer, parameter :: nq=100
    real(dl) dum1(nq+1),dum2(nq+1)
    real(dl), intent(in) :: am
    real(dl), intent(out) ::  rhonu,pnu
    integer i
    real(dl) q,aq,v,aqdn,adq


    !  q is the comoving momentum in units of k_B*T_nu0/c.
    !  Integrate up to qmax and then use asymptotic expansion for remainder.
    adq=qmax/nq
    dum1(1)=0._dl
    dum2(1)=0._dl
    do  i=1,nq
       q=i*adq
       aq=am/q
       v=1._dl/sqrt(1._dl+aq*aq)
       aqdn=adq*q*q*q/(exp(q)+1._dl)
       dum1(i+1)=aqdn/v
       dum2(i+1)=aqdn*v
    end do
    call splint(dum1,rhonu,nq+1)
    call splint(dum2,pnu,nq+1)
    !  Apply asymptotic corrrection for q>qmax and normalize by relativistic
    !  energy density.
    rhonu=(rhonu+dum1(nq+1)/adq)/const
    pnu=(pnu+dum2(nq+1)/adq)/const/3._dl

  end subroutine nuRhoPres

  !cccccccccccccccccccccccccccccccccccccccccc
  subroutine Nu_background(am,rhonu,pnu)
    use precision
    use ModelParams
    real(dl), intent(in) :: am
    real(dl), intent(out) :: rhonu, pnu

    !  Compute massive neutrino density and pressure in units of the mean
    !  density of one eigenstate of massless neutrinos.  Use cubic splines to
    !  interpolate from a table.

    real(dl) d
    integer i

    if (am <= am_minp) then
       rhonu=1._dl + const2*am**2
       pnu=(2-rhonu)/3._dl
       return
    else if (am >= am_maxp) then
       rhonu = 3/(2*const)*(zeta3*am + (15*zeta5)/2/am)
       pnu = 900._dl/120._dl/const*(zeta5-63._dl/4*Zeta7/am**2)/am
       return
    end if


    d=log(am/am_min)/dlnam+1._dl
    i=int(d)
    d=d-i

    !  Cubic spline interpolation.
    rhonu=r1(i)+d*(dr1(i)+d*(3._dl*(r1(i+1)-r1(i))-2._dl*dr1(i) &
         -dr1(i+1)+d*(dr1(i)+dr1(i+1)+2._dl*(r1(i)-r1(i+1)))))
    pnu=p1(i)+d*(dp1(i)+d*(3._dl*(p1(i+1)-p1(i))-2._dl*dp1(i) &
         -dp1(i+1)+d*(dp1(i)+dp1(i+1)+2._dl*(p1(i)-p1(i+1)))))
    rhonu=exp(rhonu)
    pnu=exp(pnu)

  end subroutine Nu_background

  !cccccccccccccccccccccccccccccccccccccccccc
  subroutine Nu_rho(am,rhonu)
    use precision
    use ModelParams
    real(dl), intent(in) :: am
    real(dl), intent(out) :: rhonu

    !  Compute massive neutrino density in units of the mean
    !  density of one eigenstate of massless neutrinos.  Use cubic splines to
    !  interpolate from a table.

    real(dl) d
    integer i

    if (am <= am_minp) then
       rhonu=1._dl + const2*am**2
       return
    else if (am >= am_maxp) then
       rhonu = 3/(2*const)*(zeta3*am + (15*zeta5)/2/am)
       return
    end if

    d=log(am/am_min)/dlnam+1._dl
    i=int(d)
    d=d-i

    !  Cubic spline interpolation.
    rhonu=r1(i)+d*(dr1(i)+d*(3._dl*(r1(i+1)-r1(i))-2._dl*dr1(i) &
         -dr1(i+1)+d*(dr1(i)+dr1(i+1)+2._dl*(r1(i)-r1(i+1)))))
    rhonu=exp(rhonu)
  end subroutine Nu_rho

  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

  function Nu_drho(am,adotoa,rhonu) result (rhonudot)
    use precision
    use ModelParams

    !  Compute the time derivative of the mean density in massive neutrinos
    !  and the shear perturbation.
    real(dl) adotoa,rhonu,rhonudot
    real(dl) d
    real(dl), intent(IN) :: am
    integer i

    if (am< am_minp) then
       rhonudot = 2*const2*am**2*adotoa
    else if (am>am_maxp) then
       rhonudot = 3/(2*const)*(zeta3*am - (15*zeta5)/2/am)*adotoa
    else
       d=log(am/am_min)/dlnam+1._dl
       i=int(d)
       d=d-i
       !  Cubic spline interpolation for rhonudot.
       rhonudot=dr1(i)+d*(ddr1(i)+d*(3._dl*(dr1(i+1)-dr1(i)) &
            -2._dl*ddr1(i)-ddr1(i+1)+d*(ddr1(i)+ddr1(i+1) &
            +2._dl*(dr1(i)-dr1(i+1)))))

       rhonudot=rhonu*adotoa*rhonudot/dlnam
    end if

  end function Nu_drho

end module MassiveNu

! wrapper function to avoid cirular module references
subroutine init_massive_nu(has_massive_nu)
  use MassiveNu
  use ModelParams
  implicit none
  logical, intent(IN) :: has_massive_nu

  if (has_massive_nu) then
     call Nu_Init
  else
     nu_masses = 0
  end if
end subroutine init_massive_nu


!ccccccccccccccccccccccccccccccccccccccccccccccccccc

module Transfer
  use ModelData
  use Errors
  implicit none
  public
  !!Flag for axion transfer function
  integer, parameter :: Transfer_kh =1, Transfer_cdm=2,Transfer_b=3,Transfer_g=4, &
       Transfer_r=5, Transfer_nu = 6,  & !massless and massive neutrino
       Transfer_axion=7,  Transfer_f=8, & ! DM: Axions and growth rate     
       Transfer_tot=9

  integer, parameter :: Transfer_max = Transfer_tot

  logical :: transfer_interp_matterpower  = .true. !output regular grid in log k
  !set to false to output calculated values for later interpolation

  integer :: transfer_power_var = Transfer_tot
  !What to use to calulcate the output matter power spectrum and sigma_8
  !Transfer_tot uses total matter perturbation

  Type MatterTransferData
     !Computed data
     integer   ::  num_q_trans   !    number of steps in k for transfer calculation
     real(dl), dimension (:), pointer :: q_trans => NULL()
     real(dl), dimension (:,:), pointer ::  sigma_8 => NULL()
     real, dimension(:,:,:), pointer :: TransferData => NULL()
     !TransferData(entry,k_index,z_index) for entry=Tranfer_kh.. Transfer_tot
  end Type MatterTransferData

  Type MatterPowerData
     !everything is a function of k/h
     integer   ::  num_k, num_z
     real(dl), dimension(:), pointer :: log_kh => NULL(), redshifts => NULL()
     !matpower is log(P_k)
     real(dl), dimension(:,:), allocatable :: matpower, ddmat
     !if NonLinear, nonlin_ratio =  sqrt(P_nonlinear/P_linear)
     !function of k and redshift NonLinearScaling(k_index,z_index)
     real(dl), dimension(:,:), pointer :: nonlin_ratio => NULL()
  end Type MatterPowerData

  Type (MatterTransferData), save :: MT

  interface Transfer_GetMatterPower
     module procedure Transfer_GetMatterPowerD,Transfer_GetMatterPowerS
  end interface Transfer_GetMatterPower

contains

  subroutine Transfer_GetMatterPowerData(MTrans, PK_data, in, itf_only)
    !Does *NOT* include non-linear corrections
    !Get total matter power spectrum in units of (h Mpc^{-1})^3 ready for interpolation.
    !Here there definition is < Delta^2(x) > = 1/(2 pi)^3 int d^3k P_k(k)
    !We are assuming that Cls are generated so any baryonic wiggles are well sampled and that matter power
    !sepctrum is generated to beyond the CMB k_max
    Type(MatterTransferData), intent(in) :: MTrans
    Type(MatterPowerData) :: PK_data
    integer, intent(in) :: in
    integer, intent(in), optional :: itf_only
    real(dl) h, kh, k, power
    integer ik
    integer nz,itf, itf_start, itf_end


    real clock_start, clock_stop ! RH timing 
    call cpu_time(clock_start) ! RH timing  
    if (present(itf_only)) then
       itf_start=itf_only
       itf_end = itf_only
       nz = 1
    else
       itf_start=1
       nz= size(MTrans%TransferData,3)
       itf_end = nz
    end if
    PK_data%num_k = MTrans%num_q_trans
    PK_Data%num_z = nz

    allocate(PK_data%matpower(PK_data%num_k,nz))
    allocate(PK_data%ddmat(PK_data%num_k,nz))
    allocate(PK_data%nonlin_ratio(PK_data%num_k,nz))
    allocate(PK_data%log_kh(PK_data%num_k))
    allocate(PK_data%redshifts(nz))
    PK_data%redshifts = CP%Transfer%Redshifts(itf_start:itf_end)

    h = CP%H0/100

    do ik=1,MTrans%num_q_trans
       kh = MTrans%TransferData(Transfer_kh,ik,1)
       k = kh*h
       PK_data%log_kh(ik) = log(kh)
       power = ScalarPower(k,in)
       if (global_error_flag/=0) then
          call MatterPowerdata_Free(PK_data)
          return
       end if
       do itf = 1, nz
          PK_data%matpower(ik,itf) = &
               log(MTrans%TransferData(transfer_power_var,ik,itf_start+itf-1)**2*k &
               *pi*twopi*h**3*power)
       end do
    end do

    call MatterPowerdata_getsplines(PK_data)

    call cpu_time(clock_stop) ! RH timing                                                        
    !    print*, 'Total time taken RH:', clock_stop - clock_start   
  end subroutine Transfer_GetMatterPowerData

  subroutine MatterPowerData_Load(PK_data,fname)
    !Loads in kh, P_k from file for one redshiftr and one initial power spectrum
    !Not redshift is not stored in file, so not set correctly
    !Also note that output _matterpower file is already interpolated, so re-interpolating is probs not a good idea

    !Get total matter power spectrum in units of (h Mpc^{-1})^3 ready for interpolation.
    !Here there definition is < Delta^2(x) > = 1/(2 pi)^3 int d^3k P_k(k)
    use AmlUtils
    character(LEN=*) :: fname
    Type(MatterPowerData) :: PK_data
    real(dl)kh, Pk
    integer ik
    integer nz


    nz = 1
    call openTxtFile(fname, fileio_unit)

    PK_data%num_k = FileLines(fileio_unit)
    PK_Data%num_z = 1

    allocate(PK_data%matpower(PK_data%num_k,nz))
    allocate(PK_data%ddmat(PK_data%num_k,nz))
    allocate(PK_data%nonlin_ratio(PK_data%num_k,nz))
    allocate(PK_data%log_kh(PK_data%num_k))

    allocate(PK_data%redshifts(nz))
    PK_data%redshifts = 0

    do ik=1,PK_data%num_k
       read (fileio_unit,*) kh, Pk
       PK_data%matpower(ik,1) = log(Pk)
       PK_data%log_kh(ik) = log(kh)
    end do

    call MatterPowerdata_getsplines(PK_data)

  end subroutine MatterPowerData_Load


  subroutine MatterPowerdata_getsplines(PK_data)
    Type(MatterPowerData) :: PK_data
    integer i
    real(dl), parameter :: cllo=1.e30_dl,clhi=1.e30_dl

    real clock_start, clock_stop ! RH timing
    call cpu_time(clock_start) ! RH timing
    do i = 1,PK_Data%num_z
       call spline(PK_data%log_kh,PK_data%matpower(1,i),PK_data%num_k,&
            cllo,clhi,PK_data%ddmat(1,i))
    end do
    call cpu_time(clock_stop) ! RH timing                                                        
    !    print*, 'Total time taken RH:', clock_stop - clock_start
  end subroutine MatterPowerdata_getsplines

  subroutine MatterPowerdata_MakeNonlinear(PK_data)
    Type(MatterPowerData) :: PK_data

    call NonLinear_GetRatios(PK_data)
    PK_data%matpower = PK_data%matpower +  2*log(PK_data%nonlin_ratio)
    call MatterPowerdata_getsplines(PK_data)

  end subroutine MatterPowerdata_MakeNonlinear

  subroutine MatterPowerdata_Free(PK_data)
    Type(MatterPowerData) :: PK_data
    integer i

    deallocate(PK_data%log_kh,stat=i)
    deallocate(PK_data%matpower,stat=i)
    deallocate(PK_data%ddmat,stat=i)
    deallocate(PK_data%nonlin_ratio,stat=i)
    deallocate(PK_data%redshifts,stat=i)
    call MatterPowerdata_Nullify(PK_data)

  end subroutine MatterPowerdata_Free

  subroutine MatterPowerdata_Nullify(PK_data)
    Type(MatterPowerData) :: PK_data

    nullify(PK_data%log_kh)
    nullify(PK_data%nonlin_ratio)
    nullify(PK_data%redshifts)

  end subroutine MatterPowerdata_Nullify

  function MatterPowerData_k(PK,  kh, itf) result(outpower)
    !Get matter power spectrum at particular k/h by interpolation
    Type(MatterPowerData) :: PK
    integer, intent(in) :: itf
    real (dl), intent(in) :: kh
    real(dl) :: logk
    integer llo,lhi
    real(dl) outpower, dp
    real(dl) ho,a0,b0
    integer, save :: i_last = 1

    logk = log(kh)
    if (logk < PK%log_kh(1)) then
       dp = (PK%matpower(2,itf) -  PK%matpower(1,itf)) / &
            ( PK%log_kh(2)-PK%log_kh(1) )
       outpower = PK%matpower(1,itf) + dp*(logk - PK%log_kh(1))
       !    outpower = exp(max(-30._dl,outpower))
       outpower = exp(outpower) ! RH change for axions !RL 122024 moved location so that the second category is safter
    else if (logk > PK%log_kh(PK%num_k)) then
       !Do dodgy linear extrapolation on assumption accuracy of result won't matter
       !RL 122024 this can be too dodgy for light DM masses that our results may break. Since the result won't matter we directly set it to zero
       outpower = 0._dl
       !dp = (PK%matpower(PK%num_k,itf) -  PK%matpower(PK%num_k-1,itf)) / &
       !     ( PK%log_kh(PK%num_k)-PK%log_kh(PK%num_k-1) )
       !outpower = PK%matpower(PK%num_k,itf) + dp*(logk - PK%log_kh(PK%num_k))
    else
       llo=min(i_last,PK%num_k)
       do while (PK%log_kh(llo) > logk)
          llo=llo-1
       end do
       do while (PK%log_kh(llo+1)< logk)
          llo=llo+1
       end do
       i_last =llo
       lhi=llo+1
       ho=PK%log_kh(lhi)-PK%log_kh(llo)
       a0=(PK%log_kh(lhi)-logk)/ho
       b0=1-a0

       outpower = a0*PK%matpower(llo,itf)+ b0*PK%matpower(lhi,itf)+&
            ((a0**3-a0)* PK%ddmat(llo,itf) &
            +(b0**3-b0)*PK%ddmat(lhi,itf))*ho**2/6
       outpower = PK%matpower(1,itf) + dp*(logk - PK%log_kh(1))
       !    outpower = exp(max(-30._dl,outpower))
       outpower = exp(outpower) ! RH change for axions !RL 122024 moved location so that the second category is safter
    end if

  end function MatterPowerData_k

  subroutine Transfer_GetMatterPowerS(MTrans,outpower, itf, in, minkh, dlnkh, npoints)
    Type(MatterTransferData), intent(in) :: MTrans
    integer, intent(in) :: itf, in, npoints
    real, intent(out) :: outpower(*)
    real, intent(in) :: minkh, dlnkh
    real(dl) :: outpowerd(npoints)
    real(dl):: minkhd, dlnkhd

    minkhd = minkh; dlnkhd = dlnkh
    call Transfer_GetMatterPowerD(MTrans,outpowerd, itf, in, minkhd, dlnkhd, npoints)
    outpower(1:npoints) = outpowerd(1:npoints)

  end subroutine Transfer_GetMatterPowerS

  !JD 08/13 for nonlinear lensing of CMB + LSS compatibility
  !Changed input variable from itf to itf_PK because we are looking for the itf_PK'th
  !redshift in the PK_redshifts array.  The position of this redshift in the master redshift
  !array, itf, is given by itf = CP%Transfer%Pk_redshifts_index(itf_PK)
  !Also changed (CP%NonLinear/=NonLinear_None) to
  !CP%NonLinear/=NonLinear_none .and. CP%NonLinear/=NonLinear_Lens)
  subroutine Transfer_GetMatterPowerD(MTrans,outpower, itf_PK, in, minkh, dlnkh, npoints)
    !Allows for non-smooth priordial spectra
    !if CP%Nonlinear/ = NonLinear_none includes non-linear evolution
    !Get total matter power spectrum at logarithmically equal intervals dlnkh of k/h starting at minkh
    !in units of (h Mpc^{-1})^3.
    !Here there definition is < Delta^2(x) > = 1/(2 pi)^3 int d^3k P_k(k)
    !We are assuming that Cls are generated so any baryonic wiggles are well sampled and that matter power
    !sepctrum is generated to beyond the CMB k_max
    Type(MatterTransferData), intent(in) :: MTrans
    Type(MatterPowerData) :: PK

    integer, intent(in) :: itf_PK, in, npoints
    real(dl), intent(out) :: outpower(npoints)
    real(dl), intent(in) :: minkh, dlnkh
    real(dl), parameter :: cllo=1.e30_dl,clhi=1.e30_dl
    integer ik, llo,il,lhi,lastix
    real(dl) matpower(MTrans%num_q_trans), kh, kvals(MTrans%num_q_trans), ddmat(MTrans%num_q_trans)
    real(dl) atransfer,xi, a0, b0, ho, logmink,k, h
    integer itf

    itf = CP%Transfer%PK_redshifts_index(itf_PK)

    if (npoints < 2) stop 'Need at least 2 points in Transfer_GetMatterPower'

    !         if (minkh < MTrans%TransferData(Transfer_kh,1,itf)) then
    !            stop 'Transfer_GetMatterPower: kh out of computed region'
    !          end if
    if (minkh*exp((npoints-1)*dlnkh) > MTrans%TransferData(Transfer_kh,MTrans%num_q_trans,itf) &
         .and. FeedbackLevel > 0 ) &
         write(*,*) 'Warning: extrapolating matter power in Transfer_GetMatterPower'


    if (CP%NonLinear/=NonLinear_none .and. CP%NonLinear/=NonLinear_Lens) then
       call Transfer_GetMatterPowerData(MTrans, PK, in, itf)
       call NonLinear_GetRatios(PK)
    end if

    h = CP%H0/100
    logmink = log(minkh)
    do ik=1,MTrans%num_q_trans
       kh = MTrans%TransferData(Transfer_kh,ik,itf)
       k = kh*h
       kvals(ik) = log(kh)
       atransfer=MTrans%TransferData(transfer_power_var,ik,itf)
       if (CP%NonLinear/=NonLinear_none .and. CP%NonLinear/=NonLinear_Lens) &
            atransfer = atransfer* PK%nonlin_ratio(ik,1) !only one element, this itf
       matpower(ik) = log(atransfer**2*k*pi*twopi*h**3)
       !Put in power spectrum later: transfer functions should be smooth, initial power may not be
    end do

    call spline(kvals,matpower,MTrans%num_q_trans,cllo,clhi,ddmat)

    llo=1
    lastix = npoints + 1
    do il=1, npoints
       xi=logmink + dlnkh*(il-1)
       if (xi < kvals(1)) then
          outpower(il)=-30.
          cycle
       end if
       do while ((xi > kvals(llo+1)).and.(llo < MTrans%num_q_trans))
          llo=llo+1
          if (llo >= MTrans%num_q_trans) exit
       end do
       if (llo == MTrans%num_q_trans) then
          lastix = il
          exit
       end if
       lhi=llo+1
       ho=kvals(lhi)-kvals(llo)
       a0=(kvals(lhi)-xi)/ho
       b0=(xi-kvals(llo))/ho

       outpower(il) = a0*matpower(llo)+ b0*matpower(lhi)+((a0**3-a0)* ddmat(llo) &
            +(b0**3-b0)*ddmat(lhi))*ho**2/6
    end do

    do while (lastix <= npoints)
       !Do linear extrapolation in the log
       !Obviouly inaccurate, non-linear etc, but OK if only using in tails of window functions
       outpower(lastix) = 2*outpower(lastix-1) - outpower(lastix-2)
       lastix = lastix+1
    end do

    !    outpower = exp(max(-30.d0,outpower))
    outpower = exp(outpower) ! RH change for axions

    do il = 1, npoints
       k = exp(logmink + dlnkh*(il-1))*h
       outpower(il) = outpower(il) * ScalarPower(k,in)
       if (global_error_flag /= 0) exit
    end do

    if (CP%NonLinear/=NonLinear_none .and. CP%NonLinear/=NonLinear_Lens) call MatterPowerdata_Free(PK)

  end subroutine Transfer_GetMatterPowerD

  subroutine Transfer_Get_sigma8(MTrans, sigr8)
    use MassiveNu
    Type(MatterTransferData) :: MTrans
    integer ik, itf, in
    real(dl) kh, k, h, x, win, delta
    real(dl) lnk, dlnk, lnko
    real(dl) dsig8, dsig8o, sig8, sig8o, powers
    real(dl), intent(IN) :: sigr8
    !JD 08/13 Changes in here to PK arrays and variables
    integer itf_PK
    !Calculate MTrans%sigma_8^2 = int dk/k win**2 T_k**2 P(k), where win is the FT of a spherical top hat
    !of radius sigr8 h^{-1} Mpc

    if (global_error_flag /= 0) return

    H=CP%h0/100._dl
    do in = 1, CP%InitPower%nn
       do itf_PK=1,CP%Transfer%PK_num_redshifts
          itf = CP%Transfer%PK_redshifts_index(itf_PK)
          lnko=0
          dsig8o=0
          sig8=0
          sig8o=0
          do ik=1, MTrans%num_q_trans
             kh = MTrans%TransferData(Transfer_kh,ik,itf)
             if (kh==0) cycle
             k = kh*H

             delta = k**2*MTrans%TransferData(transfer_power_var,ik,itf)
             !if (CP%NonLinear/=NonLinear_None) delta= delta* MTrans%NonLinearScaling(ik,itf)
             !sigma_8 defined "as though it were linear"

             x= kh *sigr8
             win =3*(sin(x)-x*cos(x))/x**3
             lnk=log(k)
             if (ik==1) then
                dlnk=0.5_dl
                !Approx for 2._dl/(CP%InitPower%an(in)+3)  [From int_0^k_1 dk/k k^4 P(k)]
                !Contribution should be very small in any case
             else
                dlnk=lnk-lnko
             end if
             powers = ScalarPower(k,in)
             dsig8=(win*delta)**2*powers
             sig8=sig8+(dsig8+dsig8o)*dlnk/2
             dsig8o=dsig8
             lnko=lnk
          end do

          MTrans%sigma_8(itf_PK,in) = sqrt(sig8)
       end do
    end do

  end subroutine Transfer_Get_sigma8

  subroutine Transfer_output_Sig8(MTrans)
    Type(MatterTransferData), intent(in) :: MTrans
    integer in, j
    !JD 08/13 Changes in here to PK arrays and variables
    integer j_PK
    real(dl) z_osc !RL 121924 for comparison
    z_osc = 1._dl/CP%a_osc - 1._dl
    if (z_osc .lt. 0._dl) then
       z_osc = 0._dl
    end if
    
    !!write(*, *) 'CP%a_osc, z_osc', CP%a_osc, z_osc
    !!!real(dl) omegam_0 !RL 091924 temporary

    !!!omegam_0 = CP%omegac + CP%omegab + CP%omegan !RL 091924
    !!!write(*, *) 'm_ovH0', CP%m_ovH0
    !!!if (CP%m_ovH0 .ge. 10._dl) then !RL 091924
    !!!   omegam_0 = omegam_0 + CP%omegaax
    !!!end if
    
    do in=1, CP%InitPower%nn
       if (CP%InitPower%nn>1)  write(*,*) 'Power spectrum : ', in
       do j_PK=1, CP%Transfer%PK_num_redshifts
          j = CP%Transfer%PK_redshifts_index(j_PK)
          write(*,*) 'at z = ',real(CP%Transfer%redshifts(j)), ' sigma8 (all matter)=', real(MTrans%sigma_8(j_PK,in))
          if (real(CP%Transfer%redshifts(j)) .gt. z_osc) then
             write(*, '(A, F9.5, A, F9.5, A)') 'Note: z = ', real(CP%Transfer%redshifts(j)), &
                  &' is before the axion switch point z = ', z_osc, &
                  &', hence T(k) is defined differently from that after the switch point.'
          end if         
          !!!write(*, *) 'Writing both sigma_8 and Omega_m(z=0) to file, please make sure only z=0 is involved'
          !!!write(*, '(36e52.42e3)') ThermoDerivedParams( derived_zstar ), ThermoDerivedParams( derived_rstar ),  ThermoDerivedParams( derived_thetastar ), real(MTrans%sigma_8(j_PK,in)), real(MTrans%sigma_8(j_PK,in))*sqrt(omegam_0/0.3_dl)
          !!write(02222404, '(36e52.42e3)') ThermoDerivedParams( derived_zstar ), ThermoDerivedParams( derived_rstar ),  ThermoDerivedParams( derived_thetastar ), real(MTrans%sigma_8(j_PK,in)), omegam_0
       end do
    end do

  end subroutine Transfer_output_Sig8

  subroutine Transfer_Allocate(MTrans)
    Type(MatterTransferData) :: MTrans
    integer st

    deallocate(MTrans%q_trans, STAT = st)
    deallocate(MTrans%TransferData, STAT = st)
    deallocate(MTrans%sigma_8, STAT = st)
    allocate(MTrans%q_trans(MTrans%num_q_trans))
    allocate(MTrans%TransferData(Transfer_max,MTrans%num_q_trans,CP%Transfer%num_redshifts))
    !JD 08/13 Changes in here to PK arrays and variables
    allocate(MTrans%sigma_8(CP%Transfer%PK_num_redshifts, CP%InitPower%nn))

  end  subroutine Transfer_Allocate

  subroutine Transfer_Free(MTrans)
    Type(MatterTransferData):: MTrans
    integer st

    deallocate(MTrans%q_trans, STAT = st)
    deallocate(MTrans%TransferData, STAT = st)
    deallocate(MTrans%sigma_8, STAT = st)
    nullify(MTrans%q_trans)
    nullify(MTrans%TransferData)
    nullify(MTrans%sigma_8)

  end subroutine Transfer_Free

  !JD 08/13 Changes for nonlinear lensing of CMB + MPK compatibility
  !Changed function below to write to only P%NLL_*redshifts* variables
  subroutine Transfer_SetForNonlinearLensing(P)
    Type(TransferParams) :: P
    integer i
    real maxRedshift

    P%kmax = max(P%kmax,5*AccuracyBoost)
    P%k_per_logint  = 0
    maxRedshift = 10

    !    P%NLL_num_redshifts =  nint(10*AccuracyBoost) ! RH original 
    P%NLL_num_redshifts =  nint(100*AccuracyBoost) ! RH change for axions


    if (HighAccuracyDefault .and. AccuracyBoost>=2) then
       !only notionally more accuracy, more stable for RS
       maxRedshift =15
    end if
    if (P%NLL_num_redshifts > max_transfer_redshifts) &
         stop 'Transfer_SetForNonlinearLensing: Too many redshifts'
    do i=1,P%NLL_num_redshifts
       P%NLL_redshifts(i) = real(P%NLL_num_redshifts-i)/(P%NLL_num_redshifts/maxRedshift)
    end do

  end subroutine Transfer_SetForNonlinearLensing



  subroutine Transfer_SaveToFiles(MTrans,FileNames)
    use IniFile
    Type(MatterTransferData), intent(in) :: MTrans
    !!    Type(CAMBParams) :: CP !RL 0803 for output
    integer i,ik
    character(LEN=Ini_max_string_len), intent(IN) :: FileNames(*)
    !JD 08/13 Changes in here to PK arrays and variables
    integer i_PK

    do i_PK=1, CP%Transfer%PK_num_redshifts
       if (FileNames(i_PK) /= '') then
          i = CP%Transfer%PK_redshifts_index(i_PK)
          open(unit=fileio_unit,file=FileNames(i_PK),form='formatted',status='replace')
          do ik=1,MTrans%num_q_trans
             if (MTrans%TransferData(Transfer_kh,ik,i)/=0) then
                !                    write(fileio_unit,'(7E14.6)') MTrans%TransferData(Transfer_kh:Transfer_max,ik,i)
                write(fileio_unit,'(9E14.6)') MTrans%TransferData(Transfer_kh:Transfer_max,ik,i) ! axion
                !!!write(fileio_unit,'(36e52.42)') MTrans%TransferData(Transfer_kh:Transfer_max,ik,i) ! RL
             end if
          end do
          close(fileio_unit)
       end if
    end do


  end subroutine Transfer_SaveToFiles

  subroutine Transfer_SaveMatterPower(MTrans, FileNames)
    use IniFile
    !Export files of total  matter power spectra in h^{-1} Mpc units, against k/h.
    Type(MatterTransferData), intent(in) :: MTrans
    character(LEN=Ini_max_string_len), intent(IN) :: FileNames(*)
    integer itf,in,i
    integer points
    real, dimension(:,:,:), allocatable :: outpower
    character(LEN=80) fmt
    real minkh,dlnkh
    Type(MatterPowerData) :: PK_data
    integer ncol
    !JD 08/13 Changes in here to PK arrays and variables
    integer itf_PK

    ncol=1

    write (fmt,*) CP%InitPower%nn+1
    fmt = '('//trim(adjustl(fmt))//'E15.5)'
    do itf=1, CP%Transfer%PK_num_redshifts
       if (FileNames(itf) /= '') then
          if (.not. transfer_interp_matterpower ) then
             itf_PK = CP%Transfer%PK_redshifts_index(itf)

             points = MTrans%num_q_trans
             allocate(outpower(points,CP%InitPower%nn,ncol))

             do in = 1, CP%InitPower%nn
                call Transfer_GetMatterPowerData(MTrans, PK_data, in, itf_PK)
                !JD 08/13 for nonlinear lensing of CMB + LSS compatibility
                !Changed (CP%NonLinear/=NonLinear_None) to CP%NonLinear/=NonLinear_none .and. CP%NonLinear/=NonLinear_Lens)
                if(CP%NonLinear/=NonLinear_none .and. CP%NonLinear/=NonLinear_Lens)&
                     call MatterPowerdata_MakeNonlinear(PK_Data)

                outpower(:,in,1) = exp(PK_data%matpower(:,1))
                call MatterPowerdata_Free(PK_Data)
             end do

             open(unit=fileio_unit,file=FileNames(itf),form='formatted',status='replace')
             do i=1,points
                write (fileio_unit, fmt) MTrans%TransferData(Transfer_kh,i,1),outpower(i,1:CP%InitPower%nn,:)
             end do
             close(fileio_unit)
          else
             minkh = 1e-4
             dlnkh = 0.02
             points = log(MTrans%TransferData(Transfer_kh,MTrans%num_q_trans,itf)/minkh)/dlnkh+1
             !             dlnkh = log(MTrans%TransferData(Transfer_kh,MTrans%num_q_trans,itf)/minkh)/(points-0.999)
             allocate(outpower(points,CP%InitPower%nn,1))
             do in = 1, CP%InitPower%nn
                call Transfer_GetMatterPowerS(MTrans,outpower(1,in,1), itf, in, minkh,dlnkh, points)
             end do

             open(unit=fileio_unit,file=FileNames(itf),form='formatted',status='replace')
             do i=1,points
                write (fileio_unit, fmt) minkh*exp((i-1)*dlnkh),outpower(i,1:CP%InitPower%nn,1)
             end do
             close(fileio_unit)
          end if

          deallocate(outpower)
       end if
    end do

  end subroutine Transfer_SaveMatterPower

  !JD 08/13 New function for nonlinear lensing of CMB + MPK compatibility
  !Build master redshift array from array of desired Nonlinear lensing (NLL)
  !redshifts and an array of desired Power spectrum (PK) redshifts.
  !At the same time fill arrays for NLL and PK that indicate indices
  !of their desired redshifts in the master redshift array.
  !Finally define number of redshifts in master array. This is usually given by:
  !P%num_redshifts = P%PK_num_redshifts + P%NLL_num_redshifts - 1.  The -1 comes
  !from the fact that z=0 is in both arrays
  subroutine Transfer_SortAndIndexRedshifts(P)
    Type(TransferParams) :: P
    integer i, iPK, iNLL
    i=0
    iPK=1
    iNLL=1
    do while (iPk<=P%PK_num_redshifts .or. iNLL<=P%NLL_num_redshifts)
       !JD write the next line like this to account for roundoff issues with ==. Preference given to PK_Redshift
       if(max(P%NLL_redshifts(iNLL),P%PK_redshifts(iPK))-min(P%NLL_redshifts(iNLL),P%PK_redshifts(iPK))<1.d-5)then
          i=i+1
          P%redshifts(i)=P%PK_redshifts(iPK)
          P%PK_redshifts_index(iPK)=i
          P%NLL_redshifts_index(iNLL)=i
          iPK=iPK+1
          iNLL=iNLL+1
       else if(P%NLL_redshifts(iNLL)>P%PK_redshifts(iPK))then
          i=i+1
          P%redshifts(i)=P%NLL_redshifts(iNLL)
          P%NLL_redshifts_index(iNLL)=i
          iNLL=iNLL+1
       else
          i=i+1
          P%redshifts(i)=P%PK_redshifts(iPK)
          P%PK_redshifts_index(iPK)=i
          iPK=iPK+1
       end if
    end do
    P%num_redshifts=i
    if (P%num_redshifts > max_transfer_redshifts) &
         call Mpistop('Transfer_SortAndIndexRedshifts: Too many redshifts')
  end subroutine Transfer_SortAndIndexRedshifts

end module Transfer


!ccccccccccccccccccccccccccccccccccccccccccccccccccc

module ThermoData
  use ModelData
  implicit none
  private
  integer,parameter :: nthermo=20000

  real(dl) tb(nthermo),cs2(nthermo),xe(nthermo)
  real(dl) dcs2(nthermo)
  real(dl) dotmu(nthermo), ddotmu(nthermo)
  real(dl) sdotmu(nthermo),emmu(nthermo)
  real(dl) demmu(nthermo)
  real(dl) dddotmu(nthermo),ddddotmu(nthermo)
  real(dl) winlens(nthermo),dwinlens(nthermo), scalefactor(nthermo)
  real(dl) tauminn,dlntau,Maxtau
  real(dl), dimension(:), allocatable :: vis,dvis,ddvis,expmmu,dopac, opac, lenswin
  logical, parameter :: dowinlens = .false.

  real(dl) :: tight_tau, actual_opt_depth
  !Times when 1/(opacity*tau) = 0.01, for use switching tight coupling approximation
  real(dl) :: matter_verydom_tau
  real(dl) :: r_drag0, z_star, z_drag  !!JH for updated BAO likelihood.

  public thermo,inithermo,vis,opac,expmmu,dvis,dopac,ddvis,lenswin, tight_tau,&
       Thermo_OpacityToTime,matter_verydom_tau, ThermoData_Free,&
       z_star, z_drag  !!JH for updated BAO likelihood.
contains

  subroutine thermo(tau,cs2b,opacity, dopacity)
    !Compute unperturbed sound speed squared,
    !and ionization fraction by interpolating pre-computed tables.
    !If requested also get time derivative of opacity
    implicit none
    real(dl) tau,cs2b,opacity
    real(dl), intent(out), optional :: dopacity

    integer i
    real(dl) d

    d=log(tau/tauminn)/dlntau+1._dl
    i=int(d)
    d=d-i
    if (i < 1) then
       !Linear interpolation if out of bounds (should not occur).
       cs2b=cs2(1)+(d+i-1)*dcs2(1)
       opacity=dotmu(1)+(d-1)*ddotmu(1)
       stop 'thermo out of bounds'
    else if (i >= nthermo) then
       cs2b=cs2(nthermo)+(d+i-nthermo)*dcs2(nthermo)
       opacity=dotmu(nthermo)+(d-nthermo)*ddotmu(nthermo)
       if (present(dopacity)) then
          dopacity = 0
          stop 'thermo: shouldn''t happen'
       end if
    else
       !Cubic spline interpolation.
       cs2b=cs2(i)+d*(dcs2(i)+d*(3*(cs2(i+1)-cs2(i))  &
            -2*dcs2(i)-dcs2(i+1)+d*(dcs2(i)+dcs2(i+1)  &
            +2*(cs2(i)-cs2(i+1)))))
       opacity=dotmu(i)+d*(ddotmu(i)+d*(3*(dotmu(i+1)-dotmu(i)) &
            -2*ddotmu(i)-ddotmu(i+1)+d*(ddotmu(i)+ddotmu(i+1) &
            +2*(dotmu(i)-dotmu(i+1)))))

       if (present(dopacity)) then
          dopacity=(ddotmu(i)+d*(dddotmu(i)+d*(3*(ddotmu(i+1)  &
               -ddotmu(i))-2*dddotmu(i)-dddotmu(i+1)+d*(dddotmu(i) &
               +dddotmu(i+1)+2*(ddotmu(i)-ddotmu(i+1))))))/(tau*dlntau)
       end if
    end if
    !write(*, *) 'cs2, (3*cs2)-1', cs2b, 3._dl * cs2b - 1._dl !RL checked cs2b, the sound speed of baryons
  end subroutine thermo


  function Thermo_OpacityToTime(opacity)
    real(dl), intent(in) :: opacity
    integer j
    real(dl) Thermo_OpacityToTime
    !Do this the bad slow way for now..
    !The answer is approximate
    j =1
    do while(dotmu(j)> opacity)
       j=j+1
    end do

    Thermo_OpacityToTime = exp((j-1)*dlntau)*tauminn

  end function Thermo_OpacityToTime

  subroutine inithermo(taumin,taumax)
    !  Compute and save unperturbed baryon temperature and ionization fraction
    !  as a function of time.  With nthermo=10000, xe(tau) has a relative
    ! accuracy (numerical integration precision) better than 1.e-5.
    use constants
    use precision
    use ModelParams
    use MassiveNu
    real(dl) taumin,taumax


    real(dl) tau01,adot0,a0,a02,x1,x2,barssc,dtau
    real(dl) xe0,tau,a,a2
    real(dl) adot,tg0,ahalf,adothalf,fe,thomc,thomc0,etc,a2t
    real(dl) dtbdla,vfi,cf1,maxvis, visi !RL 122123 - renamed vis to visi to avoid conflicts with the public table
    integer ncount,i,j1,j2,iv,ns
    real(dl) spline_data(nthermo)
    real(dl) last_dotmu
    real(dl) dtauda  !diff of tau w.CP%r.t a and integration
    external dtauda
    real(dl) a_verydom
    real(dl) awin_lens1p,awin_lens2p,dwing_lens, rs, DA
    real(dl) z_eq, a_eq
    real(dl) rombint
    integer noutput
    external rombint
    integer j_test !RL 122123
    real(dl) alo_test, ahi_test, d_a_test !RL 122123
    !!real(dl) Hosc_thresh !RL 121123
    !!Hosc_thresh = (CP%ma/3._dl)*CP%H0_in_Mpc_inv/CP%H0_eV !RL: the beginning of oscillations - if it exceeds taurend then do not consider
!!!!!! !RL 122223 smoothing out the delta function of dotmu
    integer :: half_w, j_sm, tau_n !RL 010224
    real(dl) :: wt, sum_sm, sum_sm_test !RL122923
    real(dl) :: recdotmu_ro(nthermo), recxe_sm(nthermo)
!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !axion version of recfast call                                                                                      \
    call Recombination_Init(CP%Recomb, CP%omegac,CP%omegab,CP%Omegan,&
         CP%Omegav,CP%h0,CP%tcmb,CP%yhe,CP%omegaax,CP%omegar,CP%aeq, CP%a_osc)
    ! Data structures not passed through params because camb data structures significantly different

    ! previous version (for vanilla_lcdm)
    !    call Recombination_Init(CP%Recomb, CP%omegac, CP%omegab,CP%Omegan, CP%Omegav, &
    !    CP%h0,CP%tcmb,CP%yhe,CP%Num_Nu_massless + CP%Num_Nu_massive)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    !almost all the time spent here
    if (global_error_flag/=0) return
    Maxtau=taumax
    tight_tau = 0
    actual_opt_depth = 0
    ncount=0
    z_star=0.d0
    z_drag=0.d0
    thomc0= Compton_CT * CP%tcmb**4
    r_drag0 = 3.d0/4.d0*CP%omegab*grhom/grhog
    !thomc0=5.0577d-8*CP%tcmb**4

    tauminn=0.05d0*taumin
    dlntau=log(CP%tau0/tauminn)/(nthermo-1)
    last_dotmu = 0

    matter_verydom_tau = 0
    a_verydom = AccuracyBoost*5*(grhog+grhornomass)/(grhoc+grhob)

    !  Initial conditions: assume radiation-dominated universe.
    tau01=tauminn
    adot0=adotrad
    a0=adotrad*tauminn
    a02=a0*a0
    !  Let's also initialize scaleFactor before the loop - note that a02, etc. will change later
    !write(*, *) 'Rayne, after initial assignment, scaleFactor(1), a0', scaleFactor(1), a0
    scaleFactor(1) = a0
    !  Assume that any entropy generation occurs before tauminn.
    !  This gives wrong temperature before pair annihilation, but
    !  the error is harmless.
    tb(1)=CP%tcmb/a0
    xe0=1._dl
    x1=0._dl
    x2=1._dl
    xe(1)=xe0+0.25d0*CP%yhe/(1._dl-CP%yhe)*(x1+2*x2)
    barssc=barssc0*(1._dl-0.75d0*CP%yhe+(1._dl-CP%yhe)*xe(1))
    cs2(1)=4._dl/3._dl*barssc*tb(1)
    dotmu(1)=xe(1)*akthom/a02
!!!recdotmu_ro(1) = dotmu(1) !RL 122223
    !!recdotmu_ro(1) = dotmu(1)*(tauminn**4) !RL 123023
    tau_n = 0 !RL 010224 - scaling power of dotmu to make the smoothing easier !121524 - set tau_n = 0 to turn smoothing off since we don't need it
    recdotmu_ro(1) = dotmu(1)*(tauminn**tau_n) !RL 010224
    sdotmu(1)=0

    !Initialization of the half-width, and weight in the box, for the box-car smooth filter
    half_w = 0 !RL 010224 !121524 - since we have recombination skip, we turn smoothing off, half_w = -
    !!!!write(*, *) 'half_w', half_w
    wt = 1._dl/(2*half_w + 1) !Assign the weight for each element in the window)
!!!!write(*, *) 'wt', wt

    !RL 122223 First isolate the rough recombination part of dotmu
    do i = 2, nthermo
       tau=tauminn*exp((i-1)*dlntau)
       dtau=tau-tau01
       !  Integrate Friedmann equation using inverse trapezoidal rule.
       a=a0+adot0*dtau
       scaleFactor(i)=a
       a2=a*a
       !!   write(*, *) 'Rayne, computing a before, the scaleFactor(i), a', scaleFactor(i), a
       !Order is very important. Evaluate a first and then recdotmu_ro
       adot=1/dtauda(a)
       a=a0+2._dl*dtau/(1._dl/adot0+1._dl/adot)
       recdotmu_ro(i) = Recombination_xe(a)*akthom/a2
       !RL 123023: multiply recdotmu_ro by tau^4 to make the data flatter before smoothing
       !!recdotmu_ro(i) = recdotmu_ro(i)*(tau**4)
       !RL 010224
       recdotmu_ro(i) = recdotmu_ro(i)*(tau**tau_n)
       !Don't forget the end update. This is a loop integration
       a0=a
       tau01=tau
       adot0=adot
       !!write(*, *) 'tau', tau
    end do
    !RL 122223 Then run a box car to iron through this dotmu array

    do i = 1, nthermo
       if (i .lt. half_w+1) then
          ! Handle start of the array (reduced window size)
          sum_sm = 0._dl
          do j_sm = 1, i + half_w
             !!write(*, *) ' in array start (1), j_sm', j_sm
             sum_sm = sum_sm + recdotmu_ro(j_sm)
          end do
          ! Then get the mirrored entries
          do j_sm = 1, half_w-i +1
             !!write(*, *) ' in array start (2, mirror), j_sm', j_sm
             sum_sm = sum_sm + recdotmu_ro(j_sm)
          end do
          !!write(*, *) 'in array start, i, SUM_SM, SUM_SM*wt, recdotmu_ro(i)', i, sum_sm, sum_sm*wt,recdotmu_ro(i)
          !!write(*, *) 'in array start, i, Recombination_xe(scaleFactor(i)), sum_sm*wt/(akthom/(scaleFactor(i)**2._dl))', i, Recombination_xe(scaleFactor(i)), sum_sm*wt/(akthom/(scaleFactor(i)**2._dl))
       else if (i .gt. nthermo-half_w) then
          ! Handle end of the array (reduced window size)
          sum_sm = 0._dl
          do j_sm = i-half_w, nthermo
             !!write(*, *) 'in array end (1), j_sm', j_sm
             sum_sm = sum_sm + recdotmu_ro(j_sm)
          end do
          ! Then get the mirrored entries
          do j_sm = 2*nthermo-(i+half_w) +1, nthermo
             !!write(*, *) 'in array end (2, mirror)'
             sum_sm = sum_sm + recdotmu_ro(j_sm)
          end do
          !!write(*, *) 'in array end, i, SUM_SM, SUM_SM*wt, recdotmu_ro(i)', i, sum_sm, sum_sm*wt,recdotmu_ro(i)
          !!write(*, *) 'in array end, i, Recombination_xe(scaleFactor(i)), sum_sm*wt/(akthom/(scaleFactor(i)**2._dl))', i, Recombination_xe(scaleFactor(i)), sum_sm*wt/(akthom/(scaleFactor(i)**2._dl))
       else
          ! Middle of the array (full window size) (Just take double loop)
          !!!if (i == half_w+1) then
             ! Initialize sum for the first full window
             sum_sm = 0._dl
             do j_sm = i - half_w, i + half_w
                !!write(*, *) 'in array middle, just starting first loop'
                sum_sm = sum_sm + recdotmu_ro(j_sm)
             end do
             !!sum_sm_test = sum_sm
             !!write(*, *) 'in array middle 1, i, SUM_SM, SUM_SM*wt, recdotmu_ro(i)', i, sum_sm, sum_sm*wt,recdotmu_ro(i)
             !!write(*, *) 'in array middle 1, i, Recombination_xe(scaleFactor(i)), sum_sm*wt/(akthom/(scaleFactor(i)**2._dl)), their fractional difference', i, Recombination_xe(scaleFactor(i)), sum_sm*wt/(akthom/(scaleFactor(i)**2._dl)), (Recombination_xe(scaleFactor(i)))/(sum_sm*wt/(akthom/(scaleFactor(i)**2._dl))) - 1.0_dl

          !!!else
             ! Update sum for subsequent windows
!!!if (i == half_w + 2) then
!!!      write(*, *) 'Rayne, i, sum_sm, recdotmu_ro(i-half_w-1), recdotmu_ro(i-half_w), recdotmu_ro(i), recdotmu_ro(i+half_w)', i, sum_sm, recdotmu_ro(i-half_w-1), recdotmu_ro(i-half_w), recdotmu_ro(i), recdotmu_ro(i+half_w)
!!!end if
             !!!sum_sm = sum_sm + recdotmu_ro(i+half_w) - recdotmu_ro(i-half_w-1)
             !!sum_sm = 0._dl
             !!do j_sm = i - half_w, i + half_w
                !!write(*, *) 'in array middle, just starting first loop'
             !!   sum_sm = sum_sm + recdotmu_ro(j_sm)
             !!end do
             !!sum_sm_test = sum_sm_test + recdotmu_ro(i+half_w) - recdotmu_ro(i-half_w-1)
             !!write(*, *) 'Rayne, i, sum_sm, sum_sm_test, their fractional difference', i, sum_sm, sum_sm_test, sum_sm_test/sum_sm - 1._dl
!!!if (i == half_w + 2) then
!!!      write(*, *) 'Rayne, i, the new sum_sm', sum_sm
!!!      write(*, *) 'in array middle 2, i, SUM_SM, SUM_SM*wt, recdotmu_ro(i)', i, sum_sm, sum_sm*wt,recdotmu_ro(i)
!!!      write(*, *) 'in array middle 2, i, Recombination_xe(scaleFactor(i)), sum_sm*wt/(akthom/(scaleFactor(i)**2._dl))', i, Recombination_xe(scaleFactor(i)), sum_sm*wt/(akthom/(scaleFactor(i)**2._dl))
          !!!end if

!!! end if

       end if
       !Obtain the smoothed version of recxe
       recxe_sm(i) = sum_sm*wt/(akthom/(scaleFactor(i)**2._dl))
!!!if (i .lt. half_w+1) then
!!!!write(*, *) 'at the start, akthom, scalefactor(i)**2._dl, recxe_sm(i)', akthom, scalefactor(i)**2._dl, recxe_sm(i)
!!!end if
       !!write(*, *) 'Rayne, half_w = 0, recxe_sm(i)*(akthom/(scalefactor(i)**2._dl)), recdotmu_ro(i), their fractional difference', recxe_sm(i)*(akthom/(scaleFactor(i)**2._dl)), recdotmu_ro(i), recxe_sm(i)*(akthom/(scaleFactor(i)**2._dl))/recdotmu_ro(i) - 1._dl
!!!write(*, *) 'Rayne, half_w, recxe_sm(i)*(akthom/(scalefactor(i)**2._dl)), recdotmu_ro(i), their fractional difference', half_w, recxe_sm(i)*(akthom/(scaleFactor(i)**2._dl)), recdotmu_ro(i), recxe_sm(i)*(akthom/(scaleFactor(i)**2._dl))/recdotmu_ro(i) - 1._dl
       !!!write(666666, '(36e52.42e3)') scaleFactor(i), recdotmu_ro(i), sum_sm*wt, recxe_sm(i), Recombination_xe(scaleFactor(i))
    end do
    !Finally, before formally assigning the final xe, update xe(1) which will always be in recombination
!!!write(*, *) 'before reassigning xe(1), xe(1), recxe_sm(1), their fractional difference', xe(1), recxe_sm(1), xe(1)/recxe_sm(1) - 1._dl
    !!write(*, *) 'RAYNE, before reassigning xe(1), a02, scaleFactor(1)**2._dl, their fractional difference',  a02, scaleFactor(1)**2._dl,  a02/(scaleFactor(1)**2._dl) - 1._dl
!!!xe(1) = recxe_sm(1) !RL 122223
    !!xe(1) = recxe_sm(1)/(tauminn**4) !RL 123023
    xe(1) = recxe_sm(1)/(tauminn**tau_n) !RL 010224
!!!write(*, *) 'also dotmu(1), xe(1)*akthom/a02 (now xe(1) is already the smoothed one), their fractional difference', dotmu(1), xe(1)*akthom/a02, dotmu(1)/(xe(1)*akthom/a02) - 1._dl !RL tried and true
    dotmu(1) = xe(1)*akthom/a02 !RL 122223 reassign dotmu(1)
!!!!!!!write(*, *) 'Rayne, normal evaluation, scaleFactor', scaleFactor
    !Continue with the normal evaluation, but replacing Recombination_xe(a) with recxe_sm
    !Note that we have to reset the initial conditions assume radiation-dominated universe. I can't just reuse scaleFactor(i) since the a evaluated at different stages of a single loop below are both used in the integration...
    tau01=tauminn
    adot0=adotrad
    a0=adotrad*tauminn
    a02=a0*a0
    do i=2,nthermo
       tau=tauminn*exp((i-1)*dlntau)
       dtau=tau-tau01
       !  Integrate Friedmann equation using inverse trapezoidal rule.
       a=a0+adot0*dtau
!!!write(*, *) 'Rayne, computing a again, a, the existing scaleFactor(i), their fractional difference', a, scaleFactor(i), scaleFactor(i)/a - 1._dl
       scaleFactor(i)=a
       a2=a*a

       adot=1/dtauda(a)

       if (matter_verydom_tau ==0 .and. a > a_verydom) then
          matter_verydom_tau = tau
       end if

       a=a0+2._dl*dtau/(1._dl/adot0+1._dl/adot)
       !  Baryon temperature evolution: adiabatic except for Thomson cooling.
       !  Use  quadrature solution.
       ! This is redundant as also calculated in REFCAST, but agrees well before reionization
       tg0=CP%tcmb/a0
       ahalf=0.5d0*(a0+a)
       adothalf=0.5d0*(adot0+adot)
       !  fe=number of free electrons divided by total number of free baryon
       !  particles (e+p+H+He).  Evaluate at timstep i-1 for convenience; if
       !  more accuracy is required (unlikely) then this can be iterated with
       !  the solution of the ionization equation.
       fe=(1._dl-CP%yhe)*xe(i-1)/(1._dl-0.75d0*CP%yhe+(1._dl-CP%yhe)*xe(i-1))
       thomc=thomc0*fe/adothalf/ahalf**3
       etc=exp(-thomc*(a-a0))
       a2t=a0*a0*(tb(i-1)-tg0)*etc-CP%tcmb/thomc*(1._dl-etc)
       tb(i)=CP%tcmb/a+a2t/(a*a)

       ! If there is re-ionization, smoothly increase xe to the
       ! requested value.
       if (CP%Reion%Reionization .and. tau > CP%ReionHist%tau_start) then
          if(ncount == 0) then
             ncount=i-1
          end if
          !!xe(i) = Reionization_xe(a, tau, xe(ncount)) !default
          !RL 122223
!!!!xe(i) = Reionization_xe(a, tau, recxe_sm(ncount))
!!!! RL 123023
!!!xe(i) = Reionization_xe(a, tau, recxe_sm(ncount)/(tau**4))
          !RL 010224
          xe(i) = Reionization_xe(a, tau, recxe_sm(ncount)/(tau**tau_n))
          !print *,1/a-1,xe(i)
!!!!write(*, *) 'Rayne, xe(i), Reionization_xe(a, tau, recxe_sm(ncount)), their fractional difference', xe(i), Reionization_xe(a, tau, recxe_sm(ncount)), xe(i)/Reionization_xe(a, tau, recxe_sm(ncount)) - 1.0_dl
          if (CP%AccurateReionization .and. CP%DerivedParameters) then
!!!dotmu(i)=(Recombination_xe(a) - xe(i))*akthom/a2 !default 
!!!dotmu(i) = (recxe_sm(i) - xe(i))*akthom/a2!RL 122223 *******
             !!dotmu(i) = (recxe_sm(i)/(tau**4) - xe(i))*akthom/a2!RL 123023 *******
             dotmu(i) = (recxe_sm(i)/(tau**tau_n) - xe(i))*akthom/a2!RL 010224
             if (last_dotmu /=0) then
                !!write(*, *) 'Rayne, actual_opt_depth', actual_opt_depth
                actual_opt_depth = actual_opt_depth - 2._dl*dtau/(1._dl/dotmu(i)+1._dl/last_dotmu)
             end if
             last_dotmu = dotmu(i)
          end if
       else
          !!xe(i)=Recombination_xe(a) !default
!!!xe(i) = recxe_sm(i) !RL 122223
!!!xe(i) = recxe_sm(i)/(tau**4) !RL 123023
          xe(i) = recxe_sm(i)/(tau**tau_n) !RL 010224
       end if
       !!write(*, *) 'Rayne, recdotmu_ro(i), Recombination_xe(a)*akthom/a2, their fractional diffrence', recdotmu_ro(i), (Recombination_xe(a))*akthom/a2, recdotmu_ro(i)/((Recombination_xe(a))*akthom/a2) - 1.0_dl



!!!!write(*, *) 'Rayne, after xe assignment block, xe(i), dotmu(i), last_dotmu, actual_opt_depth', xe(i), dotmu(i), last_dotmu, actual_opt_depth

       !  Baryon sound speed squared (over c**2).
       dtbdla=-2._dl*tb(i)-thomc*adothalf/adot*(a*tb(i)-CP%tcmb)
       barssc=barssc0*(1._dl-0.75d0*CP%yhe+(1._dl-CP%yhe)*xe(i))
       cs2(i)=barssc*tb(i)*(1-dtbdla/tb(i)/3._dl)


       ! Calculation of the visibility function
       dotmu(i)=xe(i)*akthom/a2

       if (tight_tau==0 .and. 1/(tau*dotmu(i)) > 0.005) tight_tau = tau !0.005
       !Tight coupling switch time when k/opacity is smaller than 1/(tau*opacity)

       if (tau < 0.001) then
          sdotmu(i)=0
       else
          sdotmu(i)=sdotmu(i-1)+2._dl*dtau/(1._dl/dotmu(i)+1._dl/dotmu(i-1))
       end if

       a0=a
       tau01=tau
       adot0=adot
!!!write(11111, '(36E52.42E3)') tau, DeltaTime(0._dl, a), a, xe(i), dotmu(i), sdotmu(i)
    end do !i


    if (CP%Reion%Reionization .and. (xe(nthermo) < 0.999d0)) then
       write(*,*)'Warning: xe at redshift zero is < 1'
       write(*,*) 'Check input parameters an Reionization_xe'
       write(*,*) 'function in the Reionization module'
    end if

    do j1=1,nthermo
       if (sdotmu(j1) - sdotmu(nthermo)< -69) then
          emmu(j1)=1.d-30
       else
          emmu(j1)=exp(sdotmu(j1)-sdotmu(nthermo))
          if (.not. CP%AccurateReionization .and. &
               actual_opt_depth==0 .and. xe(j1) < 1e-3) then
             actual_opt_depth = -sdotmu(j1)+sdotmu(nthermo)
          end if
          if (CP%AccurateReionization .and. CP%DerivedParameters .and. z_star==0.d0) then
             if (sdotmu(nthermo)-sdotmu(j1) - actual_opt_depth < 1) then
                tau01=1-(sdotmu(nthermo)-sdotmu(j1) - actual_opt_depth)
                tau01=tau01*(1._dl/dotmu(j1)+1._dl/dotmu(j1-1))/2
                z_star = 1/(scaleFactor(j1)- tau01/dtauda(scaleFactor(j1))) -1
             end if
          end if
       end if
    end do

    if (CP%AccurateReionization .and. FeedbackLevel > 0 .and. CP%DerivedParameters) then
       write(*,'("Reion opt depth      = ",f7.4)') actual_opt_depth
    end if


    iv=0
    vfi=0._dl
    ! Getting the starting and finishing times for decoupling and time of maximum visibility
    if (ncount == 0) then
       cf1=1._dl
       ns=nthermo
    else
       cf1=exp(sdotmu(nthermo)-sdotmu(ncount))
       ns=ncount
    end if
    maxvis = 0
    do j1=1,ns
       visi = emmu(j1)*dotmu(j1)
       tau = tauminn*exp((j1-1)*dlntau)
       vfi=vfi+visi*cf1*dlntau*tau
       if ((iv == 0).and.(vfi > 1.0d-7/AccuracyBoost)) then
          taurst=9._dl/10._dl*tau
          iv=1
       elseif (iv == 1) then
          if (visi > maxvis) then
             maxvis=visi
             tau_maxvis = tau
          end if
          if (vfi > 0.995) then
             taurend=tau
             iv=2
             exit
          end if
       end if
    end do

    if (iv /= 2) then
       call GlobalError('inithermo: failed to find end of recombination',error_reionization)
       print*, 'omaxh2, omch2, mass, H0', CP%omegaax*(CP%h0/100.)**2, CP%omegac*(CP%h0/100.)**2, CP%ma, CP%h0
       return
    end if

    if (dowinlens) then
       vfi=0
       awin_lens1p=0
       awin_lens2p=0
       winlens=0
       do j1=1,nthermo-1
          visi = emmu(j1)*dotmu(j1)
          tau = tauminn*exp((j1-1)*dlntau)
          vfi=vfi+visi*cf1*dlntau*tau
          if (vfi < 0.995) then
             dwing_lens =  visi*cf1*dlntau*tau / 0.995

             awin_lens1p = awin_lens1p + dwing_lens
             awin_lens2p = awin_lens2p + dwing_lens/(CP%tau0-tau)
          end if
          winlens(j1)= awin_lens1p/(CP%tau0-tau) - awin_lens2p
       end do
    end if

    ! Calculating the timesteps during recombination.

    if (CP%WantTensors) then
       dtaurec=min(dtaurec,taurst/160)/AccuracyBoost
    else
       dtaurec=min(dtaurec,taurst/40)/AccuracyBoost
       if (do_bispectrum .and. hard_bispectrum) dtaurec = dtaurec / 4
    end if
    !RL 012424
    !!!dtaurec = dtaurec*0.6_dl

    if (CP%Reion%Reionization) taurend=min(taurend,CP%ReionHist%tau_start)

    if (DebugMsgs) then
       write (*,*) 'taurst, taurend = ', taurst, taurend
    end if

    call splini(spline_data,nthermo)
    call splder(cs2,dcs2,nthermo,spline_data)
    call splder(dotmu,ddotmu,nthermo,spline_data)
    call splder(ddotmu,dddotmu,nthermo,spline_data)
    call splder(dddotmu,ddddotmu,nthermo,spline_data)
    call splder(emmu,demmu,nthermo,spline_data)
    if (dowinlens) call splder(winlens,dwinlens,nthermo,spline_data)
!!!do j_test=1,nthermo
!!!end do

    call SetTimeSteps

    !write(*, *) 'Rayne, after SetTimeSteps, TimeSteps%npoints', TimeSteps%npoints
    !$OMP PARALLEL DO DEFAULT(SHARED),SCHEDULE(STATIC)
    do j2=1,TimeSteps%npoints
       call DoThermoSpline(j2,TimeSteps%points(j2))
       !!write(*, *) 'Rayne, now vis(j2) should have no problem', vis(j2)
    end do
    !$OMP END PARALLEL DO
    !write(*, *) 'Rayne, after DoThermoSpline, vis', vis

    !RL 09062023
    call ThermoSplineOut(CP%tau_osc, CP%opac_tauosc, CP%expmmu_tauosc)
    !write(*, *) 'CP%opac_tauosc, CP%ah_osc/h0*H0_in_Mpc_inv, CP%expmmu_tauosc', CP%opac_tauosc, CP%ah_osc/(CP%H0/100.0)*CP%H0_in_Mpc_inv, CP%expmmu_tauosc

    if ((CP%want_zstar .or. CP%DerivedParameters) .and. z_star==0.d0) call find_z(optdepth,z_star)
    if (CP%want_zdrag .or. CP%DerivedParameters) call find_z(dragoptdepth,z_drag)

    if (CP%DerivedParameters) then
       !rs =rombint(dsound_da_exact,1d-8,1/(z_star+1),1d-6) 
       !RL062624 This rs should be split - and 1d-6 is the atol which should be changed throughout these two lines if it needs to be changed
       if (1d-8 .le. CP%a_osc .and. 1/(z_star+1) .gt. CP%a_osc) then       
          rs=rombint(dsound_da_exact,1d-8,CP%a_osc,1d-6) + &
               & rombint(dsound_da_exact, CP%a_osc*(1._dl+max(1d-6/100.0_dl,1.d-15)), 1/(z_star+1), 1d-6)
       else
          rs =rombint(dsound_da_exact,1d-8,1/(z_star+1),1d-6) 
       end if
       DA = AngularDiameterDistance(z_star)/(1/(z_star+1))

       ThermoDerivedParams( derived_Age ) = DeltaPhysicalTimeGyr(0.0_dl,1.0_dl)
       ThermoDerivedParams( derived_zstar ) = z_star
       ThermoDerivedParams( derived_rstar ) = rs
       ThermoDerivedParams( derived_thetastar ) = 100*rs/DA
       ThermoDerivedParams( derived_DAstar ) = DA/1000
       ThermoDerivedParams( derived_zdrag ) = z_drag
       rs =rombint(dsound_da_exact,1d-8,1._dl/(z_drag+1._dl),1d-6)
       ThermoDerivedParams( derived_rdrag ) = rs
       ThermoDerivedParams( derived_kD ) =  sqrt(1.d0/(rombint(ddamping_da, 1d-8, 1/(z_star+1), 1d-6)/6))
       ThermoDerivedParams( derived_thetaD ) =  100._dl*pi/ThermoDerivedParams( derived_kD )/DA
       z_eq = (grhob+grhoc+grhoax)/(grhog+grhornomass+sum(grhormass(1:CP%Nu_mass_eigenstates))) -1._dl
       ThermoDerivedParams( derived_zEQ ) = z_eq
       a_eq = 1._dl/(1._dl+z_eq)
       ThermoDerivedParams( derived_kEQ ) = 1._dl/(a_eq*dtauda(a_eq))
       ThermoDerivedParams( derived_thetaEQ ) = 100._dl*timeOfz( ThermoDerivedParams( derived_zEQ ))/DA
       ThermoDerivedParams( derived_theta_rs_EQ ) = 100._dl*rombint(dsound_da_exact,1d-8,a_eq,1d-6)/DA

       if (associated(BackgroundOutputs%z_outputs)) then
          if (allocated(BackgroundOutputs%H)) &
               deallocate(BackgroundOutputs%H, BackgroundOutputs%DA, BackgroundOutputs%rs_by_D_v)
          noutput = size(BackgroundOutputs%z_outputs)
          allocate(BackgroundOutputs%H(noutput), BackgroundOutputs%DA(noutput), BackgroundOutputs%rs_by_D_v(noutput))
          do i=1,noutput
             BackgroundOutputs%H(i) = HofZ(BackgroundOutputs%z_outputs(i))
             BackgroundOutputs%DA(i) = AngularDiameterDistance(BackgroundOutputs%z_outputs(i))
             BackgroundOutputs%rs_by_D_v(i) = rs/BAO_D_v_from_DA_H(BackgroundOutputs%z_outputs(i), &
                  BackgroundOutputs%DA(i),BackgroundOutputs%H(i))
          end do
       end if

       if (FeedbackLevel > 0) then
          write(*,'("Age of universe/GYr  = ",f7.3)') ThermoDerivedParams( derived_Age )
          write(*,'("zstar                = ",f8.2)') ThermoDerivedParams( derived_zstar )
          write(*,'("r_s(zstar)/Mpc       = ",f7.3)') ThermoDerivedParams( derived_rstar )
          write(*,'("100*theta            = ",f9.6)') ThermoDerivedParams( derived_thetastar )

          !!write(*, *) 'Original place for thetastar:'
          !!write(*, '(36e52.42e3)') ThermoDerivedParams( derived_zstar ), ThermoDerivedParams( derived_rstar ),  ThermoDerivedParams( derived_thetastar )
          write(*,'("zdrag                = ",f8.2)') ThermoDerivedParams( derived_zdrag )
          write(*,'("r_s(zdrag)/Mpc       = ",f7.2)') ThermoDerivedParams( derived_rdrag )

          write(*,'("k_D(zstar) Mpc       = ",f7.4)') ThermoDerivedParams( derived_kD )
          write(*,'("100*theta_D          = ",f9.6)') ThermoDerivedParams( derived_thetaD )
!!!!!!!!!!!!!!!!!!!!!!!!
          !DG: Output of equality redshift suppressed
          !Axions can behave as matter or dark energy depending on their mass,
          !and so there are two possible definitions (counting them as matter
          !or not  of the quality redshift in the presence of 
          !ultra-light axions. To avoid ambiguity in interpretation, we suppress this output
          !Initial times for all integrations are chosen sufficiently deep into radiation domination
          !that they are well before equality under both definitions
          !!            write(*,'("z_EQ (if v_nu=1)     = ",f8.2)') ThermoDerivedParams( derived_zEQ )
          !!            write(*,'("100*theta_EQ         = ",f9.6)') ThermoDerivedParams( derived_thetaEQ )
!!!!!!!!!!!!!!!!!!!!!! 
       end if
    end if

  end subroutine inithermo


  subroutine SetTimeSteps
    real(dl) dtau0, dtauosc !RL 121323: adding dtauosc for timestep refinements around tauosc
    integer nri0, nstep

    call Ranges_Init(TimeSteps)
    !write(*, *) 'After Ranges_Init, Timesteps%npoints', TimeSteps%npoints
    !write(*, *) 'Rayne, DeltaTime(0, askipst), DeltaTime(0, askip)', DeltaTime(0._dl, 1._dl/2098._dl), DeltaTime(0._dl, 1._dl/901._dl)
    !Create arrays out of the region information.
    !dtaurec = dtaurec/(10._dl) !RL 120723

    call Ranges_Add_delta(TimeSteps, taurst, taurend, dtaurec) !default
    !call Ranges_Add_delta(TimeSteps, taurst/1000._dl, taurend, dtaurec) !RL 042524
    !call Ranges_Add_delta(TimeSteps, taurst, taurend, dtaurec/10._dl) !RL 041824
    !call Ranges_Add_delta(TimeSteps, taurst, taurend, dtaurec/1000._dl) !RL 092923
!! !!    if (CP%tau_osc .gt. taurst) then
!! !!      dtaurec = dtaurec+1._dl
!! !!    dtauosc = CP%tau_osc/int(6._dl*CP%dfac)
!! !!    dtauosc = dtauosc/1000._dl
!! !!    call Ranges_Add_delta(TimeSteps, max(CP%tau_osc-1.5_dl*dtauosc, taurst), min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0), dtauosc)
!! !!    call Ranges_Add_delta(TimeSteps, max(CP%tau_osc-1.5_dl*dtauosc, taurst)-int((max(CP%tau_osc-1.5_dl*dtauosc, taurst)-taurst)/dtaurec)*dtaurec, max(CP%tau_osc-1.5_dl*dtauosc, taurst), dtaurec) !RL 010424
!! !!    write(*, *) 'SOS: start', max(CP%tau_osc-1.5_dl*dtauosc, taurst)-int((max(CP%tau_osc-1.5_dl*dtauosc, taurst)-taurst)/dtaurec)*dtaurec
!! !!    call Ranges_Add_delta(TimeSteps, min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0), min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0)+int((taurend-min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0))/dtaurec)*dtaurec, dtaurec)
!! !!    write(*, *) 'SOS: end', min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0)+int((taurend-min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0))/dtaurec)*dtaurec
!! !!    end if
    !!!write(*, *) 'After Ranges_Add_delta (before taurend), Timesteps%npoints, taurend, dtaurec', TimeSteps%npoints, taurend, dtaurec

    ! Calculating the timesteps after recombination
    if (CP%WantTensors) then
       dtau0=max(taurst/40,Maxtau/2000._dl/AccuracyBoost)
    else
       dtau0=Maxtau/500._dl/AccuracyBoost
       if (do_bispectrum) dtau0 = dtau0/3
       !Don't need this since adding in Limber on small scales
       !  if (CP%DoLensing) dtau0=dtau0/2
       !  if (CP%AccurateBB) dtau0=dtau0/3 !Need to get C_Phi accurate on small scales
    end if
    !dtau0 = dtau0/(CP%dfac/10._dl) !RL 102023
    !dtau0 = dtau0/(10._dl) !RL 120723

    call Ranges_Add_delta(TimeSteps,taurend, CP%tau0, dtau0) !default
!!!write(*, *) 'After Ranges_Add_delta (after taurend), Timesteps%npoints', TimeSteps%npoints
    !call Ranges_Add_delta(TimeSteps,taurend, CP%tau0, dtau0/2._dl) !RL 102023
    !call Ranges_Add_delta(TimeSteps,taurend, CP%tau0, dtau0/10._dl) !RL 041824
    !call Ranges_Add_delta(TimeSteps,taurend, CP%tau0, dtau0/1000._dl) 

    !!!write(*, *) 'Rayne, taurst, taurend, CP%tau0', taurst, taurend, CP%tau0

    if (CP%Reion%Reionization) then
       !write(*, *) 'Rayne, reionization, CP%ReionHist%tau_start,CP%ReionHist%tau_complete', CP%ReionHist%tau_start,CP%ReionHist%tau_complete
       nri0=int(Reionization_timesteps(CP%ReionHist)*AccuracyBoost) !default
       !nri0=int(Reionization_timesteps(CP%ReionHist)*AccuracyBoost*2._dl) !RL 101923
       !nri0=int(Reionization_timesteps(CP%ReionHist)*AccuracyBoost*10._dl) !RL 041824
       !nri0=int(Reionization_timesteps(CP%ReionHist)*AccuracyBoost*1000._dl) 
       !nri0 = nri0/10._dl !RL 120723
       !Steps while reionization going from zero to maximum
       call Ranges_Add(TimeSteps,CP%ReionHist%tau_start,CP%ReionHist%tau_complete,nri0)
    end if
   !!! write(*, *) 'After Ranges_Add_delta (reion), nri0, Timesteps%npoints', nri0, TimeSteps%npoints

    !!write(*, *) 'Before refinement, taurst, CP%tau_osc/CP%dfac, 1._dl/CP%a_osc', taurst, CP%tau_osc/CP%dfac, 1._dl/CP%a_osc
    !dtauosc = CP%tau_osc/int(1._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(2._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(6._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(5._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(12._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(24._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(48._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(100._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(200._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(1000._dl*CP%dfac)
    !dtauosc = CP%tau_osc/int(6000._dl*CP%dfac)
    !dtauosc = 0.276627303517404700416992824330009170808000E-1_dl
    
    !dtauosc =dtau0
!!!dtauosc =dtau0/2._dl
!!!write(*, *) 'Before Ranges_Add_delta, dtauosc', dtauosc
!RL 061924 Everything should happen only if we have a switch - and use a_osc from the background to definitively say whether we have a switch or not, to avoid the small but finite mis-correspondence between tau_osc and a_osc
if (CP%a_osc .le. 1._dl) then
    !!!!- Add the coarse refinement only if tau*>taurend
    !!!!- Always add the fine refinement around tau* if tau*>taurstart
    if (CP%tau_osc .gt. taurst) then
       !call Ranges_Add_delta(TimeSteps, 1.5_dl*dtauosc, min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, 2.5_dl*dtauosc, min(CP%tau_osc+2.5_dl*dtauosc, CP%tau0), dtauosc)

       !call Ranges_Add_delta(TimeSteps, 12.5_dl*dtauosc, min(CP%tau_osc+12.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, 24.5_dl*dtauosc, min(CP%tau_osc+24.5_dl*dtauosc, CP%tau0), dtauosc)
       !!call Ranges_Add_delta(TimeSteps, 100.5_dl*dtauosc, min(CP%tau_osc+100.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, 200.5_dl*dtauosc, min(CP%tau_osc+200.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, max(1000.5_dl*dtauosc, taurst), min(CP%tau_osc+1000.5_dl*dtauosc, CP%tau0), dtauosc) !make sure there's no "end smaller than start issue"
!!!call Ranges_Add_delta(TimeSteps, 0.276765617169163391508845961652696132660000E2_dl, 0.304303865234321051502774935215711593627000E3_dl, dtauosc)
        !!call Ranges_Add_delta(TimeSteps, 0.276765617169163391508845961652696132660000E2_dl, 0.404303865234321051502774935215711593627000E3_dl, dtauosc)
         !!write(*, *) 'Rayne, tauosc add delta, dtauosc, 1000.5_dl*dtauosc, min(CP%tau_osc+1000.5_dl*dtauosc, CP%tau0)'
         !!write(*, '(36E52.42E3)') dtauosc, 1000.5_dl*dtauosc, min(CP%tau_osc+1000.5_dl*dtauosc, CP%tau0)
       !call Ranges_Add_delta(TimeSteps, 2000.5_dl*dtauosc, min(CP%tau_osc+2000.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, 12.5_dl*dtauosc, min(CP%tau_osc+3000.5_dl*dtauosc, CP%tau0), dtauosc)
       !!call Ranges_Add_delta(TimeSteps, 12.5_dl*dtauosc, CP%tau0, dtauosc)
       !Then make dtauosc super fine around tauosc
         dtauosc = CP%tau_osc/int(6000._dl*CP%dfac)
         !dtauosc = CP%tau_osc/int(12000._dl*CP%dfac)
         !dtauosc = CP%tau_osc/int(6000000._dl*CP%dfac)
         !!write(*, *) 'Rayne, ultrafine, dtauosc', dtauosc
         call Ranges_Add_delta(TimeSteps, max(CP%tau_osc-6.5_dl*dtauosc, taurst), min(CP%tau_osc+6.5_dl*dtauosc, CP%tau0), dtauosc)!RL
       !call Ranges_Add_delta(TimeSteps, max(CP%tau_osc-2.5_dl*dtauosc, taurst), min(CP%tau_osc+2.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, max(CP%tau_osc- 1500.5_dl*dtauosc, taurst), min(CP%tau_osc+1500.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, max(CP%tau_osc- 1000.5_dl*dtauosc, taurst), min(CP%tau_osc+1000.5_dl*dtauosc, CP%tau0), dtauosc)
       !!write(*, *) 'max(CP%tau_osc- 1000.5_dl*dtauosc, taurst), min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0)', max(CP%tau_osc- 1000.5_dl*dtauosc, taurst), min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0)
       !!call Ranges_Add_delta(TimeSteps, max(CP%tau_osc- 1000.5_dl*dtauosc, taurst), min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, max(CP%tau_osc- 2000.5_dl*dtauosc, taurst), min(CP%tau_osc+2000.5_dl*dtauosc, CP%tau0), dtauosc)
       
       !call Ranges_Add_delta(TimeSteps, 24.5_dl*dtauosc, min(CP%tau_osc+4.5_dl*dtauosc, CP%tau0), dtauosc)
       end if
    if (CP%tau_osc .gt. taurend) then
       dtauosc = dtauosc*1000._dl
       call Ranges_Add_delta(TimeSteps, max(6.5_dl*dtauosc, taurend), min(CP%tau_osc+6.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, max(12.5_dl*dtauosc, taurend), min(CP%tau_osc+12.5_dl*dtauosc, CP%tau0), dtauosc)
       !call Ranges_Add_delta(TimeSteps, max(1000.5_dl*dtauosc, taurend), min(CP%tau_osc+1000.5_dl*dtauosc, CP%tau0), dtauosc)
    !write(*, *) 'Rayne, coarse, dtau0, dtauosc, dtaurec', dtau0, dtauosc, dtaurec
    end if
end if
    !Further refinement at the boundary to make sure the Cl integration is good
!!!dtauosc = min(dtaurec*2._dl, abs(taurend-CP%tau_osc)*2._dl)
!!!write(*, *) 'Borderline dtauosc', dtauosc
!!!call Ranges_Add(TimeSteps, max(tauminn, CP%tau_osc-1.5_dl*dtauosc), min(CP%tau_osc+1.5_dl*dtauosc, CP%tau0), 4) !RL 121923 - the number of this refinement won't change

    call Ranges_GetArray(TimeSteps)
    !!write(*, *) 'After Ranges_GetArray, Timesteps%points', TimeSteps%points
    nstep = TimeSteps%npoints

    if (allocated(vis)) then
       deallocate(vis,dvis,ddvis,expmmu,dopac, opac)
       if (dowinlens) deallocate(lenswin)
    end if
    allocate(vis(nstep),dvis(nstep),ddvis(nstep),expmmu(nstep),dopac(nstep),opac(nstep))
    if (dowinlens) allocate(lenswin(nstep))

    if (DebugMsgs .and. FeedbackLevel > 0) write(*,*) 'Set ',nstep, ' time steps'

  end subroutine SetTimeSteps


  subroutine ThermoData_Free
    if (allocated(vis)) then
       deallocate(vis,dvis,ddvis,expmmu,dopac, opac)
       if (dowinlens) deallocate(lenswin)
    end if
    call Ranges_Free(TimeSteps)

  end subroutine ThermoData_Free

  !cccccccccccccc
  subroutine DoThermoSpline(j2,tau)
    integer j2,i
    real(dl) d,ddopac,tau
    !real(dl) opac_test, expmmu_test !RL testing

    !     Cubic-spline interpolation.
    d=log(tau/tauminn)/dlntau+1._dl
    i=int(d)

    d=d-i
    if (i < nthermo) then
       opac(j2)=dotmu(i)+d*(ddotmu(i)+d*(3._dl*(dotmu(i+1)-dotmu(i)) &
            -2._dl*ddotmu(i)-ddotmu(i+1)+d*(ddotmu(i)+ddotmu(i+1) &
            +2._dl*(dotmu(i)-dotmu(i+1)))))
       dopac(j2)=(ddotmu(i)+d*(dddotmu(i)+d*(3._dl*(ddotmu(i+1)  &
            -ddotmu(i))-2._dl*dddotmu(i)-dddotmu(i+1)+d*(dddotmu(i) &
            +dddotmu(i+1)+2._dl*(ddotmu(i)-ddotmu(i+1))))))/(tau &
            *dlntau)
       ddopac=(dddotmu(i)+d*(ddddotmu(i)+d*(3._dl*(dddotmu(i+1) &
            -dddotmu(i))-2._dl*ddddotmu(i)-ddddotmu(i+1)  &
            +d*(ddddotmu(i)+ddddotmu(i+1)+2._dl*(dddotmu(i) &
            -dddotmu(i+1)))))-(dlntau**2)*tau*dopac(j2)) &
            /(tau*dlntau)**2
       expmmu(j2)=emmu(i)+d*(demmu(i)+d*(3._dl*(emmu(i+1)-emmu(i)) &
            -2._dl*demmu(i)-demmu(i+1)+d*(demmu(i)+demmu(i+1) &
            +2._dl*(emmu(i)-emmu(i+1)))))

       if (dowinlens) then
          lenswin(j2)=winlens(i)+d*(dwinlens(i)+d*(3._dl*(winlens(i+1)-winlens(i)) &
               -2._dl*dwinlens(i)-dwinlens(i+1)+d*(dwinlens(i)+dwinlens(i+1) &
               +2._dl*(winlens(i)-winlens(i+1)))))
       end if
       vis(j2)=opac(j2)*expmmu(j2)
       dvis(j2)=expmmu(j2)*(opac(j2)**2+dopac(j2))
       ddvis(j2)=expmmu(j2)*(opac(j2)**3+3*opac(j2)*dopac(j2)+ddopac)
    else
       opac(j2)=dotmu(nthermo)
       dopac(j2)=ddotmu(nthermo)
       ddopac=dddotmu(nthermo)
       expmmu(j2)=emmu(nthermo)
       vis(j2)=opac(j2)*expmmu(j2)
       dvis(j2)=expmmu(j2)*(opac(j2)**2+dopac(j2))
       ddvis(j2)=expmmu(j2)*(opac(j2)**3+3._dl*opac(j2)*dopac(j2)+ddopac)
    end if
    !call ThermoSplineOut(tau, opac_test, expmmu_test)
    !write(*, *) 'Rayne, opac_test*expmmu_test, vis(j2), their fractional difference', opac_test*expmmu_test, vis(j2), opac_test*expmmu_test/vis(j2) - 1._dl
    !!write(22222, '(36e52.42e3)') TimeSteps%points(j2), opac(j2), dopac(j2), expmmu(j2), vis(j2), dvis(j2), ddvis(j2)
  end subroutine DoThermoSpline

  !RL 09062023 ThermoSpline for a specific tau as output. Basically the same as DoThermoSpline, only needed once per run for specific taus, such as tauosc. Written as a separate subroutine to get outside the OMP loop that calls DoThermoSpline
  subroutine ThermoSplineOut(tau, opac_tau, expmmu_tau)
    integer i
    real(dl) d,tau
    real(dl) opac_tau, expmmu_tau
    real(dl) vis_spline, d_spline, fac_spline, aa_spline !RL testing 10032023
    integer j2_spline !RL testing 10032023
    !write(*, *) 'Rayne, ThermoSplineOut should only be called once'
    !write(*, *) 'Rayne, in DoThermoSpline, CP%tau_osc', CP%tau_osc
    !     Cubic-spline interpolation.
    !write(*, *) 'Rayne, in ThermoSplineOut, vis should be nonzero already', size(vis), vis
    !write(*, *) 'Rayne, vis(48)', vis(48)
    d=log(tau/tauminn)/dlntau+1._dl
    i=int(d)

    d=d-i

    if (i < nthermo) then
       opac_tau=dotmu(i)+d*(ddotmu(i)+d*(3._dl*(dotmu(i+1)-dotmu(i)) &
            -2._dl*ddotmu(i)-ddotmu(i+1)+d*(ddotmu(i)+ddotmu(i+1) &
            +2._dl*(dotmu(i)-dotmu(i+1)))))
       !!dopac(j2)=(ddotmu(i)+d*(dddotmu(i)+d*(3._dl*(ddotmu(i+1)  &
       !!-ddotmu(i))-2._dl*dddotmu(i)-dddotmu(i+1)+d*(dddotmu(i) &
       !!+dddotmu(i+1)+2._dl*(ddotmu(i)-ddotmu(i+1))))))/(tau &
       !!*dlntau)
       !!ddopac=(dddotmu(i)+d*(ddddotmu(i)+d*(3._dl*(dddotmu(i+1) &
       !!-dddotmu(i))-2._dl*ddddotmu(i)-ddddotmu(i+1)  &
       !!+d*(ddddotmu(i)+ddddotmu(i+1)+2._dl*(dddotmu(i) &
       !!-dddotmu(i+1)))))-(dlntau**2)*tau*dopac(j2)) &
       !!/(tau*dlntau)**2
       expmmu_tau=emmu(i)+d*(demmu(i)+d*(3._dl*(emmu(i+1)-emmu(i)) &
            -2._dl*demmu(i)-demmu(i+1)+d*(demmu(i)+demmu(i+1) &
            +2._dl*(emmu(i)-emmu(i+1)))))

       !!if (dowinlens) then
       !!    lenswin(j2)=winlens(i)+d*(dwinlens(i)+d*(3._dl*(winlens(i+1)-winlens(i)) &
       !!    -2._dl*dwinlens(i)-dwinlens(i+1)+d*(dwinlens(i)+dwinlens(i+1) &
       !!    +2._dl*(winlens(i)-winlens(i+1)))))
       !!end if
       !!vis(j2)=opac(j2)*expmmu(j2)
       !!dvis(j2)=expmmu(j2)*(opac(j2)**2+dopac(j2))
       !!ddvis(j2)=expmmu(j2)*(opac(j2)**3+3*opac(j2)*dopac(j2)+ddopac)
    else
       opac_tau=dotmu(nthermo)
       !!dopac(j2)=ddotmu(nthermo)
       !!ddopac=dddotmu(nthermo)
       expmmu_tau=emmu(nthermo)
       !!vis(j2)=opac(j2)*expmmu(j2)
       !!dvis(j2)=expmmu(j2)*(opac(j2)**2+dopac(j2))
       !!ddvis(j2)=expmmu(j2)*(opac(j2)**3+3._dl*opac(j2)*dopac(j2)+ddopac)
    end if
    !RL 100323 at this point the table for the visibility function should already be constructed. I'll spline this table to see if that gives me my constructed vis from opac*expmmu
    !Find the j2 straddling tauosc
    !!do j2_spline = 1, TimeSteps%npoints - 1, 1
    !!   if (TimeSteps%points(j2_spline).lt. tau .and. TimeSteps%points(j2_spline + 1) .gt. tau) then
    !!      write(*, *) 'Rayne, found j2_spline, TimeSteps%points(j2_spline), tau,  TimeSteps%points(j2_spline + 1)', j2_spline, TimeSteps%points(j2_spline), tau,  TimeSteps%points(j2_spline + 1)
    !!      d_spline = tau - TimeSteps%points(j2_spline)
    !!      fac_spline = TimeSteps%points(j2_spline + 1) - TimeSteps%points(j2_spline)
    !!      aa_spline = (TimeSteps%points(j2_spline + 1) - tau)/fac_spline
    !!      fac_spline = fac_spline**2._dl*aa_spline/6._dl

    !Cubic spline
    !write(*, *) 'Rayne, vis(j2_spline), dvis(j2_spline), ddvis(j2_spline)', vis(j2_spline), dvis(j2_spline), ddvis(j2_spline)
    !!vis_spline = aa_spline*vis(j2_spline)+(1-aa_spline)*(vis(j2_spline+1) - ((aa_spline+1) &
    !!           *ddvis(j2_spline)+(2-aa_spline)*ddvis(j2_spline+1))*fac_spline) !cubic spline

    !!write(*, *) 'Rayne, opac_tau*expmmu_tau, vis_spline, their fractional difference', opac_tau*expmmu_tau, vis_spline, opac_tau*expmmu_tau/vis_spline - 1._dl
    !!   end if
    !!end do

  end subroutine ThermoSplineOut


  function ddamping_da(a)
    real(dl) :: ddamping_da
    real(dl), intent(in) :: a
    real(dl) :: R
    real(dl) :: dtauda
    external dtauda

    R=r_drag0*a
    !ignoring reionisation, not relevant for distance measures
    ddamping_da = (R**2 + 16*(1+R)/15)/(1+R)**2*dtauda(a)*a**2/(Recombination_xe(a)*akthom)

  end function ddamping_da


!!!!!!!!!!!!!!!!!!!
  !JH: functions and subroutines for calculating z_star and z_drag

  function doptdepth_dz(z)
    real(dl) :: doptdepth_dz
    real(dl), intent(in) :: z
    real(dl) :: a
    real(dl) :: dtauda
    external dtauda

    a = 1._dl/(1._dl+z)

    !ignoring reionisation, not relevant for distance measures
    doptdepth_dz = Recombination_xe(a)*akthom*dtauda(a)

  end function doptdepth_dz

  function optdepth(z)
    real(dl) :: rombint2
    external rombint2
    real(dl) optdepth
    real(dl),intent(in) :: z

    optdepth = rombint2(doptdepth_dz, 0.d0, z, 1d-5, 20, 100)

  end function optdepth


  function ddragoptdepth_dz(z)
    real(dl) :: ddragoptdepth_dz
    real(dl), intent(in) :: z
    real(dl) :: a
    real(dl) :: dtauda
    external dtauda

    a = 1._dl/(1._dl+z)
    ddragoptdepth_dz = doptdepth_dz(z)/r_drag0/a

  end function ddragoptdepth_dz


  function dragoptdepth(z)
    real(dl) :: rombint2
    external rombint2
    real(dl) dragoptdepth
    real(dl),intent(in) :: z

    dragoptdepth =  rombint2(ddragoptdepth_dz, 0.d0, z, 1d-5, 20, 100)

  end function dragoptdepth


  subroutine find_z(func,zout)  !find redshift at which (photon/drag) optical depth = 1
    real(dl), external :: func
    real(dl), intent(out) :: zout
    real(dl) :: try1,try2,diff,avg
    integer :: i

    try1 = 0.d0
    try2 = 10000.d0

    i=0
    diff = 10.d0
    do while (diff .gt. 1d-3)
       i=i+1
       if (i .eq. 100) then
          call GlobalError('optical depth redshift finder did not converge',error_reionization)
          zout=0
          return
       end if

       diff = func(try2)-func(try1)
       avg = 0.5d0*(try2+try1)
       if (func(avg) .gt. 1.d0) then
          try2 = avg
       else
          try1 = avg
       end if
    end do

    zout = avg

  end subroutine find_z

!!!!!!!!!!!!!!!!!!! end JH

end module ThermoData
