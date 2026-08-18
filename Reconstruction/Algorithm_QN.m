function [O_rec, phase_rec, P_rec, err_curve] = Algorithm_QN(ImagesIn, LED_Array, systemSetup, options, centerTag)
% Algorithm_QN_complete - Quasi-Newton FPM single-crop recon (complete)
% Inputs:
%   ImagesIn    - [Ny x Nx x Nimgs] cropped image stack
%   LED_Array   - cell array with LED tags ('77','6a',...)
%   systemSetup - struct with fields: LEDspacing(mm), LEDheight(mm),
%                 camPixSize(um), lambda(um), NA, magnification
%   options     - struct: maxIter, alpha, beta, IntCorr (0/1), initialPupil
%   centerTag   - e.g. '77' identify the central LED tag in LED_Array
%
% Outputs:
%   O_rec, phase_rec, P_rec, err_curve

%% 1) basic sizes and spatial-frequency sampling (dux, duy)
ImagesIn = double(ImagesIn);
[Ny, Nx, Nimgs] = size(ImagesIn);
pixSizeObj = systemSetup.camPixSize / systemSetup.magnification; % um (object plane)
FoVx = Nx * pixSizeObj;    % um
FoVy = Ny * pixSizeObj;    % um

% dux, duy: spatial-frequency sampling (1/um)
if mod(Nx,2) == 1
    dux = 1 / pixSizeObj / (Nx - 1);
else
    dux = 1 / FoVx;
end
if mod(Ny,2) == 1
    duy = 1 / pixSizeObj / (Ny - 1);
else
    duy = 1 / FoVy;
end

%% 2) LED -> frequency indices (use helper)
[idx_X, idx_Y, illuminationNA] = LEDcoord_from_array_reflect(LED_Array, centerTag, systemSetup, dux, duy);
% %% reflective mode
% [idx_X, idx_Y, illuminationNA] = LEDcoord_from_array_reflect(LED_Array, systemSetup, dux, duy);
% max distance in Fourier space between adjacent LEDs
sp0 = max([abs(diff(idx_X)), abs(diff(idx_Y))]); % 一维 cell 的相邻差值
mx = round(sp0/3);
if mx < 3
    mx = 3;
end
%% 3) compute synthetic NA and choose N_obj (canvas size)
um_m = systemSetup.NA / systemSetup.lambda; % objective bandwidth (1/um)
um_p = max(illuminationNA(:))/systemSetup.lambda + um_m; % combined max freq (1/um)
disp(['synthetic NA is ', num2str(um_p * systemSetup.lambda)]);

% estimate required object freq size in x
N_objX2 = round(2 * um_p / dux) * 2;       % even
% enforce N_objX integer multiple of Nx to avoid FT artifacts
N_objX = ceil(N_objX2 / Nx) * Nx;
if N_objX == Nx
    N_objX = N_objX * 2;
end
N_objY = round(Ny * N_objX / Nx);  % keep aspect ratio

%% 4) initialize FT/IFT, pupil, O canvas
FT  = @(x) fftshift(fft2(ifftshift(x)));
IFT = @(x) fftshift(ifft2(ifftshift(x)));

%% pupil support (binary disk, adapted to ROI size)
m = 1:Nx;
n = 1:Ny;
[mm, nn] = meshgrid(m - round((Nx+1)/2), n - round((Ny+1)/2));

% Normalise the coordinates to ensure the aspect ratio is correct
if Nx > Ny
    nn = nn * max(abs(mm(:))) / max(abs(nn(:)));
else
    mm = mm * max(abs(nn(:))) / max(abs(mm(:)));
end

% Radius (in pixels)
ridx = sqrt(mm.^2 + nn.^2);

% pupil 半径对应的索引 (由NA决定)
um_idx = um_m / min(dux, duy);

% Initial pupil (binary disk)
pupil0 = double(ridx < um_idx);

% Apply an initialization strategy (such as a plane wave or adding noise, etc.)
P = initPupil(pupil0, options.initialPupil);


%% large canvas O in frequency domain
cen0 = round(( [N_objY, N_objX] + 1 ) / 2);
O = zeros(N_objY, N_objX);

% initialize O using the first image (central LED)
idx_center_img = 1;  % The first image shows the central LED
Os = FT(sqrt(ImagesIn(:,:,idx_center_img)));

n1 = cen0 - floor([Ny, Nx]/2);
n2 = n1 + [Ny, Nx] - 1;

O(n1(1):n2(1), n1(2):n2(2)) = Os .* P;


%% 6) Intensity correction init
c = ones(1, Nimgs);   % 一A two-dimensional array whose length equals the number of LEDs

%% 7) main QN loop
err_curve = zeros(options.maxIter,1);

%Folder for intermediate reconstructions
if isfield(options,'saveIterations') && options.saveIterations == 1
    if ~isfield(options,'saveFolder')
        options.saveFolder = fullfile(pwd,'Reconstruction_Iterations');
    end

    if ~exist(options.saveFolder,'dir')
        mkdir(options.saveFolder);
    end
end

for it = 1:options.maxIter

    err_iter = zeros(Nimgs,1);

    for m = 1:Nimgs

        % frequency index for this LED
        nX = idx_X(m);
        nY = idx_Y(m);
        cen = cen0 + [nY, nX];

        % crop subregion from O
        n1r = cen(1) - floor(Ny/2);
        n2r = n1r + Ny - 1;
        n1c = cen(2) - floor(Nx/2);
        n2c = n1c + Nx - 1;

        Psi0 = O(n1r:n2r, n1c:n2c) .* P;

        % Fourier domain -> spatial domain
        psi0 = IFT(Psi0);

        I_est = abs(psi0).^2;

        I_mea = ImagesIn(:,:,m);

        % intensity correction
        if it > 1 && options.IntCorr == 1

            num = sum(sqrt(max(I_est,0)),'all');
            den = sum(sqrt(max(I_mea,0)),'all');

            if den < 1e-12
                c(m)=1;
            else
                c(m)=num/den;
            end

            c(m)=min(max(c(m),0.1),50);
        end

        % forward projection
        Psi = forward_project(psi0, I_mea*c(m), I_est, FT);

        dPsi = Psi - Psi0;

        % Object and pupil update
        [O, P] = GDUpdate_rank1( ...
            O, P, dPsi, max(abs(O(:))), ...
            cen, pupil0, options.alpha, options.beta);

        % error
        err_iter(m) = rms(I_mea(:) - I_est(:));

        if it > 1 && options.IntCorr == 1
            ImagesIn(:,:,m) = ImagesIn(:,:,m) .* c(m);
        end

    end

    err_curve(it) = mean(err_iter);

    fprintf('Iter %d/%d  RMSE=%.5f\n', ...
        it, options.maxIter, err_curve(it));


    %% =====================================================
    %% SAVE CURRENT RECONSTRUCTION
    %% =====================================================

    if isfield(options,'saveIterations') && options.saveIterations == 1

        %% -----------------------------------------------
        % 1. Fourier-domain reconstruction
        %    O(kx,ky)
        % -----------------------------------------------

        Fourier_amp = abs(O);

        % Log scale makes the Fourier spectrum easier to see
        Fourier_display = log(1 + Fourier_amp);

        % Normalize
        Fourier_display = mat2gray(Fourier_display);

        imwrite( ...
            uint16(Fourier_display * 65535), ...
            fullfile(options.saveFolder, ...
            sprintf('Fourier_iter_%02d.tiff',it)), ...
            'Compression','none');


        %% -----------------------------------------------
        % 2. Inverse Fourier transform
        %    O(x,y)
        % -----------------------------------------------

        O_iter = IFT(O);


        %% -----------------------------------------------
        % 3. Amplitude
        % -----------------------------------------------

        amplitude_iter = abs(O_iter);

        amplitude_display = mat2gray(amplitude_iter);

        imwrite( ...
            uint16(amplitude_display * 65535), ...
            fullfile(options.saveFolder, ...
            sprintf('Amplitude_iter_%02d.tiff',it)), ...
            'Compression','none');


        %% -----------------------------------------------
        % 4. Phase
        % -----------------------------------------------

        phase_iter = angle(O_iter);

        phase_display = mat2gray(phase_iter);

        imwrite( ...
            uint16(phase_display * 65535), ...
            fullfile(options.saveFolder, ...
            sprintf('Phase_iter_%02d.tiff',it)), ...
            'Compression','none');


        fprintf('  -> Saved reconstruction for iteration %d\n',it);

    end

end

%% 8) outputs
O_rec = IFT(O);
phase_rec = angle(O_rec);
P_rec = P;


end