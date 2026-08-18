function [idx_X, idx_Y, illuminationNA] = LEDcoord_from_array(LED_Array, centerTag, systemSetup, dux, duy)
% LEDCOORD_FROM_ARRAY
% Parse the LED character array and compute frequency shifts
%
% Inputs:
%   LED_Array   - cell array; each element is a string (e.g., '77', '6a', etc.)
%   centerTag  - identifier of the center LED, e.g. '77'
%   systemSetup- struct (lambda, LEDspacing [mm], LEDheight [mm])
%   dux, duy   - frequency sampling intervals (x and y directions)
%
% Outputs:
%   idx_X, idx_Y      - frequency index shifts corresponding to each LED
%   illuminationNA   - illumination NA corresponding to each LED
class(LED_Array)
N = numel(LED_Array);   % length of the 1D cell array
LEDx_idx = nan(1,N);
LEDy_idx = nan(1,N);

%--- 1. Parse the LED string array into numerical coordinates ---
for j = 1:N
    str = LED_Array{j};
    if isempty(str) || strcmp(str,'0')
        continue;
    end
    x_char = str(1);
    y_char = str(2);

    if isstrprop(x_char,'digit')
        x_val = str2double(x_char);
    else
        x_val = 10 + (double(lower(x_char)) - double('a'));
    end
    if isstrprop(y_char,'digit')
        y_val = str2double(y_char);
    else
        y_val = 10 + (double(lower(y_char)) - double('a'));
    end

    LEDx_idx(j) = x_val;
    LEDy_idx(j) = y_val;
end

%  --- 2. Find the center LED ---
cIdx = find(strcmp(LED_Array, centerTag),1);
if ~isempty(cIdx)
    % Case 1: centerTag exists in the current LED_Array
    % (e.g. BF + DF passed together)
    x0 = LEDx_idx(cIdx);
    y0 = LEDy_idx(cIdx);
else
    % Case 2: DF-only
    % centerTag is not in the DF list, but we still use it
    % to define the optical axis
    assert(numel(centerTag) >= 2, 'centerTag must have at least 2 chars like "77" or "a3".');
    x0 = char2val(centerTag(1));
    y0 = char2val(centerTag(2));
end

% --- 3. Relative physical displacement (mm) ---
dx = (LEDx_idx - x0) * systemSetup.LEDspacing;
dy = (LEDy_idx - y0) * systemSetup.LEDspacing;

% --- 4. Incident angle & numerical aperture (NA) ---
dist = sqrt(dx.^2 + dy.^2 + systemSetup.LEDheight^2);
sin_thetaX = dx ./ dist;
sin_thetaY = dy ./ dist;

illuminationNA = sqrt(sin_thetaX.^2 + sin_thetaY.^2);

% --- 5. Spatial frequency shift & index mapping ---
xFreq = sin_thetaX / systemSetup.lambda;
yFreq = sin_thetaY / systemSetup.lambda;

idx_X = round(xFreq / dux);
idx_Y = round(yFreq / duy);

end
% --- local helper ---
function v = char2val(ch)
    if isstrprop(ch,'digit')
        v = str2double(ch);
    else
        v = 10 + (double(lower(ch)) - double('a'));
    end
end