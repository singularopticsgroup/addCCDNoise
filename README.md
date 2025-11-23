Simulates the effect of noise in a CCD image based on irradiation.
  
 This function simulates the complete noise addition process in a CCD image,
starting from the irradiation values. It adds photon noise, dark signal noise,
read noise, and then converts the results into voltage values, which are
normalized by the ADC maximum value.

The simulation includes:
- Conversion from irradiation to photon counts (Eq. 12)
- Conversion from photon counts to electrons (Eq. 13)
- Adding dark signal noise (Eq. 16, 17)
- Adding read noise (Eq. 23)
- Conversion from electrons to voltage (Eq. 35)

Parameters:
image_irrad (matrix): Input grayscale image with irradiation values (normalized to [0, 1]).
params (struct): Parameters for noise simulation, including:
- pixel_size (scalar): Size of the pixel in micrometers.
- exposure_time (scalar): Exposure time in seconds.
- quantum_efficiency (scalar): Quantum efficiency of the CCD sensor.
- full_well_capacity (scalar): Maximum number of electrons a pixel can hold.
- gain (scalar): Gain of the CCD.
- read_noise (scalar): Standard deviation of the read noise.
- dark_current (scalar): Dark current rate in electrons per second.
- adc_max (scalar): Maximum ADC value.
- h (scalar): Planck's constant (default: 6.62607015e-34 J·s).
- c (scalar): Speed of light (default: 299792458 m/s).
- wavelength (scalar): Wavelength of the light (default: 550e-9 m).

Returns:
image_signal (matrix): Final image with added noise, normalized by ADC maximum.

Algorithm: M. Konnik and J. Welsh, “High-level numerical simulations of noise in ccd and cmos photosensors: review and tutorial,” arXiv (2014).
Implementation: Kamil Kalinowski
