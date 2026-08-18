function [idx_X, idx_Y, illuminationNA, kx_list, ky_list] = ...
    LEDcoord_from_array_reflect(LEDxy, centerTag, setup, dux, duy)
% LEDxy : Nx2 matrix, each row = [x_mm, y_mm]
%         By default:
%         the first N_BF LEDs correspond to Köhler bright-field (BF),
%         and the remaining LEDs correspond to dark-field (DF)

% setup : structure with fields:
%   lambda      - wavelength (mm)
%   LEDheight   - distance from DF LED to the sample (mm)
%   f1, f2      - focal lengths of the two Köhler lenses (mm)
%   f_obj       - objective focal length (mm)
%   (optional) N_BF
%               - number of BF LEDs at the beginning of LEDxy,
%                 default is 16

% dux, duy : k-space sampling interval

% Outputs:
%   idx_X, idx_Y
%       - frequency-index shifts corresponding to each LED
%
%   illuminationNA
%       - illumination numerical aperture (NA) of each LED (strict definition)
%
%   kx_list, ky_list
%       - true incident wavevector components kx and ky

N = size(LEDxy,1);

idx_X = zeros(1,N);
idx_Y = zeros(1,N);
illuminationNA = zeros(1,N);
kx_list = zeros(1,N);
ky_list = zeros(1,N);

lambda = setup.lambda;      % mm
fobj   = setup.f_obj;       % mm
m      = setup.f2 / setup.f1;  % Köhler: magnification from LED to BFP

% Number of BF LEDs: default is 16, can be manually set via setup.N_BF
if isfield(setup, 'N_BF')
    N_BF = min(setup.N_BF, N);
else
    N_BF = min(16, N);
end

z_DF = setup.LEDheight_reflective;     % Distance from DF1 LED to sample (mm)
z_DF2 = setup.LEDheight_reflective2;     % Distance from DF2 LED to sample (mm)
for j = 1:N

    %  -------- 1. Actual LED coordinates (mm) --------
    x_led = LEDxy(j,1);
    y_led = LEDxy(j,2);

    %  Shared in-plane radial distance
    r_led = hypot(x_led, y_led);

    if j <= N_BF
        %% ====== BF: Köhler illumination, imaged onto the BFP via f1–f2 ======
        xb = m * x_led;
        yb = m * y_led;
        rb = hypot(xb, yb);
    
        % theta = arctan(rb / fobj)
        % NA = rb / sqrt(rb^2 + fobj^2)
        denom_geo = sqrt(rb^2 + fobj^2);
        NA_ill    = rb / denom_geo;
        illuminationNA(j) = NA_ill;
    
        % kx, ky (strict finite-distance formulation)
        denom_k = lambda * denom_geo;
        kx = xb / denom_k;
        ky = yb / denom_k;
    
    elseif j <= N_BF + 25
        %% ====== DF1: first ring DF ======
        % theta = arctan(r_led / z_DF)
        % NA = r_led / sqrt(r_led^2 + z_DF^2)
        denom_geo = sqrt(r_led^2 + z_DF^2);
        NA_ill    = r_led / denom_geo;
        illuminationNA(j) = NA_ill;
    
        % kx, ky
        denom_k = lambda * denom_geo;
        kx = x_led / denom_k;
        ky = y_led / denom_k;
    
    else
        %% ====== DF2: second ring DF ======
        % theta = arctan(r_led / z_DF)
        % NA = r_led / sqrt(r_led^2 + z_DF^2)
        denom_geo = sqrt(r_led^2 + z_DF2^2);
        NA_ill    = r_led / denom_geo;
        illuminationNA(j) = NA_ill;
    
        % kx, ky
        denom_k = lambda * denom_geo;
        kx = x_led / denom_k;
        ky = y_led / denom_k;
    end    
    
    

    kx_list(j) = kx;
    ky_list(j) = ky;

    % -------- 5. transfer to frequency index --------
    idx_X(j) = round(kx / dux);
    idx_Y(j) = round(ky / duy);

end
end
