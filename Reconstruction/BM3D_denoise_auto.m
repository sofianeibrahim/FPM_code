function [out1, out2] = BM3D_denoise_auto(input, sigma, mode)
% BM3D_DENOISE_AUTO  Generic BM3D denoising interface
%
% Inputs:
%   input  - Can be one of the following:
%            (1) Grayscale image (uint8 / uint16 / double)
%            (2) Complex field (complex double), containing amplitude and phase
%            (3) Amplitude-only or phase-only matrix (double)
%
%   sigma  - Noise standard deviation parameter for BM3D
%
%   mode   - Denoising mode (optional):
%            'auto'   (default): Automatically detect input type
%            'amp'            : Force denoising on amplitude image
%            'phase'          : Force denoising on phase image
%            'complex'        : Input is complex field;
%                               denoise amplitude and phase separately
%
% Outputs:
%   out1   - If input is grayscale / amplitude / phase:
%              returns the denoised result
%            If input is complex field:
%              returns the denoised complex field
%
%   out2   - If input is complex field:
%              returns the denoised phase (optional output)

    if nargin < 3
        mode = 'auto';
    end
    
    % --- Automatic mode detection ---
    if strcmp(mode, 'auto')
         % Case 1: real-valued 2D matrix → treat as amplitude / grayscale image
        if isreal(input) && ndims(input) == 2
            mode = 'amp';  % Default: real-valued matrix is interpreted as amplitude
         % Case 2: complex-valued input → complex field (amplitude + phase)
        elseif ~isreal(input)
            mode = 'complex';
        % Otherwise: unsupported input type
        else
            error('Unable to automatically determine input type. Please specify mode manually.');
        end
    end
    
    %  --- 1) Grayscale image / Amplitude or Phase image ---
    if strcmp(mode, 'amp') || strcmp(mode, 'phase')
        if ~isa(input, 'double')
            input = im2double(input);
        end
        [~, denoised] = BM3D(1, input, sigma, 'lc');
        out1 = denoised;
        out2 = [];
        return;
    end
    
    % --- 2) Complex-valued field ---
    if strcmp(mode, 'complex')
        object = input;
        
        % --- Amplitude normalization ---
        mina = min(abs(object(:)));
        objectamp = abs(object) - mina;
        maxa = max(objectamp(:));
        objectamp = objectamp ./ maxa;

        % --- Phase normalization ---
        % Shift phase to start from zero, then normalize to [0, 1]
        objectphase = angle(object);
        minp = min(objectphase(:));
        objectphase = objectphase - minp;
        maxp = max(objectphase(:));
        objectphase = objectphase ./ maxp;
        
        % --- Apply BM3D separately ---
         % Denoise amplitude and phase independently
        [~, oA] = BM3D(1, objectamp, sigma, 'lc');
        [~, oP] = BM3D(1, objectphase, sigma, 'lc');
        
        % --- Denormalization & recomposition ---
        % Restore amplitude and phase to original physical ranges
        amp_denoised = (oA .* maxa + mina);
        phase_denoised = (oP .* maxp + minp);
        out1 = amp_denoised .* exp(1i .* phase_denoised); % complex-valued field
        out2 = phase_denoised; %  phase (optional output)
        return;
    end
end
