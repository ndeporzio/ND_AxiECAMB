# <a name="top"></a>AxiECAMB

Axion Effective-method in CAMB: a CAMB-based Boltzmann code with effective methods to accurately compute ultralight axion (ULA) observables in linear theory.

*[AxiECAMB, AxionCAMB, CAMB](#intro)
*[Getting Started](#basics)
*[Method](#physics)
*[Warnings](#warnings)

----------------------------------------------------------------------
#### <a name="intro"></a>AxiECAMB, AxionCAMB, CAMB

AxiECAMB (Axion Effective-method in CAMB) executes the effective method for ultralight axions in https://arxiv.org/abs/2412.15192. The method is an extension of (Passaglia and Hu 2022, https://arxiv.org/abs/2201.10238) to treat corrections for metric perturbations and the CMB, so that linear observables such as the CMB and matter power spectra can achieve subpercent accuracy for ULA parameter estimation.

AxiECAMB heavily modifies the existing ultralight axion Boltzmann code AxionCAMB (https://github.com/dgrin1/axionCAMB), which itself is based on CAMB (http://camb.info/, https://github.com/cmbant/CAMB) version Nov 2013. 

When using AxiECAMB, please cite https://arxiv.org/abs/2412.15192.

----------------------------------------------------------------------
#### <a name="basics"></a>Getting Started

If cloned to local for the first time, run make to compile the code. You can modify Makefile according to your compiler. For basic usage, modify params.ini according to desired cosmology and run ./camb params.ini.

----------------------------------------------------------------------
#### <a name="physics"></a>Method

AxiECAMB adopts ULAs with a quadratic potential and operates in synchronous gauge. It solves the exact Klein-Gordon (KG) equation from the start time to m/H = 10, and switches to an effective fluid approximation that accurately tracks the time-average of the fast oscillations in the ULA KG system. For light axion masses where m/H~10 is around equality, m/H is raised above 10 and the switch is prevented from occuring around recombination.  

In addition to these methods, AxiECAMB fixes numerous bugs and inaccuracies in AxionCAMB such that it is in general ~50% faster. 

With default settings for accuracy and k<1E3 Mpc-1, AxiECAMB will produce accurate results between m =1e-33 and 1e-18 eV.  For the lightest ULAs, KG is solved to the present day; for heavier ones ULA effects only appear at higher k. 

Our threshold for dark matter vs dark energy like ULAs is whether the mass is greater than 10 times the present Hubble, or m/H0 > 10, which is around 1.4e-32 eV. For this category, the axfrac (fraction of ULA-abundance) parameter represents the ULA fraction in dark matter, and ULA contributes to the total matter transfer function. If m/H0 < 10, axfrac refers to the ULA fraction in dark energy instead, and the matter transfer function excludes the ULA.  In this case KG is solved to the present day and present day cosmological parameters are specified as their instantaneous z=0 values not their time average.

----------------------------------------------------------------------
#### <a name="warnings"></a>Warnings

This release (v. 1.0) only pertains to adiabatic perturbations. Isocurvature is temporarily disabled and deferred to future work.

The code currently works at the default accuracy (accuracy_boost, l_accuracy_boost = 1) as extensively tested in https://arxiv.org/abs/2412.15192. Higher accuracy boost settings than default are currently under development to integrate with the accuracy of our ULA method, or higher m/H_* values at the switch. The current code accepts higher accuracy boost input if desired but will not be as accurate as the fully integrated version.

The ULA GrowthRate subroutine pertaining to SZ analysis (and other measures of the growth rate, e.g. redshift-space distortions) is currently disabled.

If the matter power spectra or transfer function is needed for z>0, one needs to be careful regarding whether z is before or after the switch point to fluid approximation, given that they are defined differently before and after the switch. The code will display a warning sign if a z>0 is requested that is before the switch.

The warning in AxionCAMB regarding non-linear options still applies.

accurateBB in params.ini should be assigned as T if accurate BB polarization power spectra are needed.
