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
    % Validate inputs
    assert(ndims(image_irrad) == 2, 'Image should be grayscale (2D matrix)');
    
    % Check for negative values 
    if any(image_irrad(:) < 0)
        warning('Image contains negative values (min=%.4f). This may indicate improper normalization.', min(image_irrad(:)));
        % Clip negative values to zero to proceed
        image_irrad = max(image_irrad, 0);
    end
    
    if nargin < 2 || isempty(params)
        params = struct();
    end
    params = setDefaultParams(params);
    params.size_image = size(image_irrad);
    
    if nargin < 3 || isempty(reference_total_power)
        % If no reference provided, use this image's total power
        reference_total_power = sum(image_irrad(:));
    end
    
    % Calculate actual total power of this image
    total_power_this_image = sum(image_irrad(:));
    
    if total_power_this_image == 0
        error('Image has zero total power - cannot process');
    end
    
    % KEY DIFFERENCE: Calculate photon count based on TOTAL power, not peak
    % We want: same reference_total_power → same total photons
    % regardless of different peak intensities
    
    % Define reference: what does reference_total_power=1.0 mean in photons?
    % Use full well capacity as the reference
    photons_per_unit_power = (params.full_well_capacity / params.quantum_efficiency) * params.exposure_time;
    
    % Calculate total photons based on reference power 
    total_photons_target = reference_total_power * photons_per_unit_power;
    
    % Distribute these photons according to THIS image's spatial profile
    % Normalize spatial distribution so it sums to 1.0
    spatial_distribution = image_irrad / total_power_this_image;
    
    % Apply the target photon count to this spatial distribution
    image_photons = spatial_distribution * total_photons_target;
    
    % Sanity check: verify total photon count matches target
    actual_total = sum(image_photons(:));
    if abs(actual_total - total_photons_target) / total_photons_target > 0.01
        warning('Photon count error: expected %.1f, got %.1f (%.1f%% error)', ...
            total_photons_target, actual_total, 100*abs(actual_total - total_photons_target)/total_photons_target);
    end
    
    % Convert photons to electrons with Poisson noise (shot noise)
    image_electrons = poissrnd(image_photons * params.quantum_efficiency);
    
    % Add dark signal noise
    image_dark_signal_noise = poissrnd(params.dark_current * params.exposure_time, params.size_image);
    image_electrons = image_electrons + image_dark_signal_noise;
    
    % Add read noise (Gaussian)
    image_read_noise = randn(params.size_image) * params.read_noise;
    image_electrons = image_electrons + image_read_noise;
    
    % Clip to full well capacity
    image_electrons = min(image_electrons, params.full_well_capacity);
    image_electrons = max(image_electrons, 0);  % No negative electrons
    
    % Convert electrons to voltage (with gain)
    image_voltage = image_electrons * params.gain;
    
    % ADC quantization
    image_voltage = round(image_voltage);
    image_voltage = min(image_voltage, params.adc_max);
    
    % Normalize by ADC max to get final signal
    image_signal = image_voltage / params.adc_max;
end

function params = setDefaultParams(params)
    % Set default CCD parameters (same as original addCDDNoise)
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
    
    for ind = 1:size(fields_and_values, 1)
        field_name = fields_and_values{ind, 1};
        field_value = fields_and_values{ind, 2};
        if ~isfield(params, field_name)
            params.(field_name) = field_value;
        end
    end
end
