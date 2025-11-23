This function simulates realistic noise in CCD/CMOS sensor images based on incident irradiation, following the complete signal chain from photons to digital output.
📚 References
Theoretical Foundation:
M. Konnik and J. Welsh, "High-level numerical simulations of noise in ccd and cmos photosensors: review and tutorial," arXiv (2014).
Code Implementation:
Kamil Kalinowski
Applied in:
Magdalena Łukowicz, Aleksandra Korzeniewska, Kamil Kalinowski, Rafał Cichowski, Rosario Porras-Aguilar, and Mateusz Szatkowski, "Accurate and Noise-Robust Wavefront Reconstruction with an Optical Vortex Wavefront Sensor", arXiv:2510.07998 (2025).

🔬 Overview
The simulation models the complete CCD/CMOS sensor pipeline:

Photon arrival → Convert irradiation to photon counts (Eq. 12)
Photoelectric conversion → Convert photons to electrons via quantum efficiency (Eq. 13)
Dark signal noise → Add thermally-generated electrons (Eq. 16, 17)
Read noise → Add electronic readout noise (Eq. 23)
Analog-to-digital conversion → Convert electrons to voltage and digitize (Eq. 35)


📥 Input Parameters
image_irrad (matrix)
Input grayscale image representing incident irradiation, normalized to [0, 1].
params (struct)
Camera sensor parameters:
ParameterDescriptionUnitspixel_sizePhysical pixel dimensionμmexposure_timeIntegration timesquantum_efficiencyPhotoelectric conversion efficiency(dimensionless, 0–1)full_well_capacityMaximum electron storage per pixele⁻gainADC conversion gainADU/e⁻read_noiseElectronic noise standard deviatione⁻ RMSdark_currentThermal electron generation ratee⁻/sadc_maxMaximum digital output valueADUhPlanck's constantJ·s (default: 6.62607015×10⁻³⁴)cSpeed of lightm/s (default: 299792458)wavelengthOperating wavelengthm (default: 550×10⁻⁹)

📤 Output
image_signal (matrix)
Final noisy image with all noise sources included, normalized by adc_max to represent the digitized sensor output.

💡 Usage Example in Matlab

% Define camera parameters
params.pixel_size = 10;              % μm
params.exposure_time = 0.1;          % s
params.quantum_efficiency = 0.7;     % 70%
params.full_well_capacity = 30000;   % e⁻
params.gain = 2;                     % ADU/e⁻
params.read_noise = 5;               % e⁻ RMS
params.dark_current = 0.1;           % e⁻/s
params.adc_max = 2^14 - 1;          % 14-bit ADC

% Add noise to normalized irradiance image
noisy_image = addCCDNoise(clean_image, params);
