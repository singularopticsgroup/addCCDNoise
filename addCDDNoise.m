function image_signal = addCDDNoise(image_irrad, params)
    % ADDCDDNOISE Simulates the effect of noise in a CCD image based on irradiation.
    %
    % This function simulates the complete noise addition process in a CCD image,
    % starting from the irradiation values. It adds photon noise, dark signal noise,
    % read noise, and then converts the results into voltage values, which are
    % normalized by the ADC maximum value.
    %
    % The simulation includes:
    %   - Conversion from irradiation to photon counts (Eq. 12)
    %   - Conversion from photon counts to electrons (Eq. 13)
    %   - Adding dark signal noise (Eq. 16, 17)
    %   - Adding read noise (Eq. 23)
    %   - Conversion from electrons to voltage (Eq. 35)
    %
    % Parameters:
    %   image_irrad (matrix): Input grayscale image with irradiation values (normalized to [0, 1]).
    %   params (struct): Parameters for noise simulation, including:
    %     - pixel_size (scalar): Size of the pixel in micrometers.
    %     - exposure_time (scalar): Exposure time in seconds.
    %     - quantum_efficiency (scalar): Quantum efficiency of the CCD sensor.
    %     - full_well_capacity (scalar): Maximum number of electrons a pixel can hold.
    %     - gain (scalar): Gain of the CCD.
    %     - read_noise (scalar): Standard deviation of the read noise.
    %     - dark_current (scalar): Dark current rate in electrons per second.
    %     - adc_max (scalar): Maximum ADC value.
    %     - h (scalar): Planck's constant (default: 6.62607015e-34 J·s).
    %     - c (scalar): Speed of light (default: 299792458 m/s).
    %     - wavelength (scalar): Wavelength of the light (default: 550e-9 m).
    %
    % Returns:
    %   image_signal (matrix): Final image with added noise, normalized by ADC maximum.
    image_irrad=image_irrad-min(image_irrad(:));
    image_irrad=image_irrad/max(image_irrad(:));
    assert(ndims(image_irrad) == 2, 'The image should be grayscale (2D matrix).');
    assert(isMatrixNormalized(image_irrad), 'The image should be normalized (values between 0 and 1).');

    if nargin < 2
        params = struct();
    end
    params = setDefaultParams(params);
    params.size_image = size(image_irrad);
    
    % Photon section
    image_photons = convertIrrad2Photons(image_irrad, params);
    
    % Electron section
    image_electrons = convertPhotons2Electrons(image_photons, params);
    image_dark_signal_noise = calcDarkSignal(params);
    
    image_electrons = image_electrons + image_dark_signal_noise;
    
    image_read_noise = calcReadNoise(params);
    image_electrons = image_electrons + image_read_noise;
    
    image_electrons = min(image_electrons, params.full_well_capacity); % Limit number of electrons to CCD limit

    % Voltage and signal section
    image_voltage = convertElectron2Voltage(image_electrons, params);

    image_signal = image_voltage / params.adc_max;
end

function params = setDefaultParams(params)
    % SETDEFAULTPARAMS Sets default values for CCD simulation parameters.
    %
    % This function initializes the parameters structure with default values for
    % the CCD simulation. If a parameter is already specified, it remains unchanged.
    %
    % Parameters:
    %   params (struct): Structure to be updated with default values.
    %
    % Returns:
    %   params (struct): Updated structure with default parameter values.

    fields_and_values = {
        'pixel_size', 10;
        'exposure_time', 0.1;
        'quantum_efficiency', 0.7;
        'full_well_capacity', 30000;
        'gain', 2;
        'read_noise', 5;
        'dark_current', 0.1;
        'adc_max', 2^14-1;
        'h', 6.62607015e-34;
        'c', 299792458;
        'wavelength', 550e-9;
    };
    
    for ind = 1 : size(fields_and_values, 1)
        field_name = fields_and_values{ind, 1};
        field_value = fields_and_values{ind, 2};
        if ~isfield(params, field_name)
            params.(field_name) = field_value;
        end
    end
end

function bool = isMatrixNormalized(matrix)
    % ISMATRIXNORMALIZED Checks if the matrix values are normalized between 0 and 1.
    %
    % This function verifies that all elements in the input matrix are within
    % the normalized range [0, 1].
    %
    % Parameters:
    %   matrix (matrix): Input matrix to be checked.
    %
    % Returns:
    %   bool (boolean): True if all values are in the range [0, 1], otherwise false.

    bool = all(matrix(:) >= 0) && all(matrix(:) <= 1);
end

function estimated_photons = convertIrrad2Photons(image_irrad, params)
    % CONVERTIRRAD2PHOTONS Converts irradiation values to photon counts.
    %
    % This function estimates the number of photons based on the input irradiation
    % values, using the quantum efficiency and full well capacity of the CCD.
    % 
    % Equation:
    %   Photon Flux = Irradiation * (Full Well Capacity / Quantum Efficiency)
    %   Estimated Photons = Photon Flux * Exposure Time
    %
    % Parameters:
    %   image_irrad (matrix): Grayscale image with irradiation values normalized to [0, 1].
    %   params (struct): Parameters including full_well_capacity, quantum_efficiency, and exposure_time.
    %
    % Returns:
    %   estimated_photons (matrix): Image with estimated photon counts.

    photon_flux = image_irrad * (params.full_well_capacity / params.quantum_efficiency);
    estimated_photons = photon_flux * params.exposure_time;
end

function image_electrons = convertPhotons2Electrons(image_photons, params)
    % CONVERTPHOTONS2ELECTRONS Converts photon counts to electron counts using Poisson distribution.
    %
    % This function simulates the conversion from photons to electrons, incorporating
    % quantum efficiency. The conversion is modeled using a Poisson distribution.
    % 
    % Equation:
    %   Electrons = Poisson(Photons * Quantum Efficiency)
    %
    % Parameters:
    %   image_photons (matrix): Image with photon counts.
    %   params (struct): Parameters including quantum_efficiency.
    %
    % Returns:
    %   image_electrons (matrix): Image with electron counts.

    image_electrons = poissrnd(image_photons * params.quantum_efficiency);
end

function image_dark_signal = calcDarkSignal(params)
    % CALCDARKSIGNAL Calculates the dark signal noise for the image.
    %
    % This function simulates the dark signal noise by generating Poisson noise
    % based on the dark current rate and exposure time.
    %
    % Equations:
    %   Dark Signal Noise = Poisson(Dark Current * Exposure Time)
    %
    % Parameters:
    %   params (struct): Parameters including dark_current and exposure_time.
    %
    % Returns:
    %   image_dark_signal (matrix): Image with simulated dark signal noise.

    image_dark_signal = poissrnd(params.dark_current * params.exposure_time, ...
                                params.size_image);
end

function image_read_noise = calcReadNoise(params)
    % CALCREADNOISE Generates read noise for the image.
    %
    % This function simulates the read noise by generating Gaussian noise based on
    % the read noise parameter.
    %
    % Equation:
    %   Read Noise = Gaussian(0, Read Noise Standard Deviation)
    %
    % Parameters:
    %   params (struct): Parameters including read_noise.
    %
    % Returns:
    %   image_read_noise (matrix): Image with simulated read noise.

    image_read_noise = randn(params.size_image) * params.read_noise;
end

function image_voltage = convertElectron2Voltage(image_electrons, params)
    % CONVERTELECTRON2VOLTAGE Converts electron counts to voltage values.
    %
    % This function converts the number of electrons to voltage values, applies gain,
    % and quantizes the voltage values based on the ADC maximum.
    %
    % Equation:
    %   Voltage = Round(Electrons * Gain)
    %   Quantized Voltage = Min(Voltage, ADC Max)
    %
    % Parameters:
    %   image_electrons (matrix): Image with electron counts.
    %   params (struct): Parameters including gain and adc_max.
    %
    % Returns:
    %   image_voltage (matrix): Image with voltage values, quantized to ADC range.

    image_voltage = image_electrons * params.gain;
    
    % Quantization
    image_voltage = round(image_voltage);
    image_voltage = min(image_voltage, params.adc_max);
end
