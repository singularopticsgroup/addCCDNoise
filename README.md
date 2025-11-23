# CCD/CMOS Noise Simulation

This function simulates realistic noise in CCD/CMOS sensor images based on incident irradiation, following the complete signal chain from photons to digital output.

## 📚 References

**Theoretical Foundation:**  
M. Konnik and J. Welsh, "High-level numerical simulations of noise in ccd and cmos photosensors: review and tutorial," arXiv (2014).

**Code Implementation:**  
Kamil Kalinowski

**Applied in:**  
Magdalena Łukowicz, Aleksandra Korzeniewska, Kamil Kalinowski, Rafał Cichowski, Rosario Porras-Aguilar, and Mateusz Szatkowski, "Accurate and Noise-Robust Wavefront Reconstruction with an Optical Vortex Wavefront Sensor", arXiv:2510.07998 (2025).

---

## 🔬 Overview

The simulation models the complete CCD/CMOS sensor pipeline:

1. **Photon arrival** → Convert irradiation to photon counts (Eq. 12)
2. **Photoelectric conversion** → Convert photons to electrons via quantum efficiency (Eq. 13)
3. **Dark signal noise** → Add thermally-generated electrons (Eq. 16, 17)
4. **Read noise** → Add electronic readout noise (Eq. 23)
5. **Analog-to-digital conversion** → Convert electrons to voltage and digitize (Eq. 35)

---

## 📥 Input Parameters

### **`image_irrad`** (matrix)
Input grayscale image representing incident irradiation, normalized to [0, 1].

### **`params`** (struct)
Camera sensor parameters:

| Parameter | Description | Units |
|-----------|-------------|-------|
| `pixel_size` | Physical pixel dimension | μm |
| `exposure_time` | Integration time | s |
| `quantum_efficiency` | Photoelectric conversion efficiency | (dimensionless, 0–1) |
| `full_well_capacity` | Maximum electron storage per pixel | e⁻ |
| `gain` | ADC conversion gain | ADU/e⁻ |
| `read_noise` | Electronic noise standard deviation | e⁻ RMS |
| `dark_current` | Thermal electron generation rate | e⁻/s |
| `adc_max` | Maximum digital output value | ADU |
| `h` | Planck's constant | J·s (default: 6.62607015×10⁻³⁴) |
| `c` | Speed of light | m/s (default: 299792458) |
| `wavelength` | Operating wavelength | m (default: 550×10⁻⁹) |

---

## 📤 Output

### **`image_signal`** (matrix)
Final noisy image with all noise sources included, normalized by `adc_max` to represent the digitized sensor output.

---

## 💡 Usage Example
```matlab
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
```
