function [O_rec, phase_rec, P_rec, err_curve] = FPM_recon_crop(ImagesIn, LED_Array, systemSetup, options)
% Single-patch FPM reconstruction (Quasi-Newton / Gerchberg–Saxton)
%
% Inputs:
%   ImagesIn    - Cropped ROI images [Ny x Nx x Nimgs]
%   LED_Array   - LED array identifier list (cell array or matrix)
%   systemSetup - System parameter structure:
%       .NA                 - Objective numerical aperture
%       .lambda             - Wavelength (um)
%       .magnification      - System magnification
%       .LEDspacing         - LED pitch (mm)
%       .LEDheight          - LED-to-sample distance (mm)
%       .camPixSize         - Camera pixel size (um)
%   options     - Reconstruction options:
%       .alpha, .beta       - Object / pupil update step sizes
%       .maxIter            - Maximum number of iterations
%       .algorithm          - '1': Quasi-Newton, '2': GS
%       .useGPU             - Enable GPU acceleration (0/1)
%       .initialPupil       - Initial pupil type:
%                             1 = ones, 2 = Tukey window, 3 = Gaussian
%       .IntCorr            - Enable intensity correction (0/1)
%   cLED        - Center LED index in LEDsUsed [y0, x0]
%
% Outputs:
%   O_rec       - Reconstructed complex object field
%   phase_rec   - Reconstructed phase
%   P_rec       - Reconstructed pupil function
%   err_curve   - Iteration error curve

%% ---------- 1. Basic parameters ----------
[Ny, Nx, Nimgs] = size(ImagesIn);
pixSizeObj = systemSetup.camPixSize / systemSetup.magnification; % Object-plane pixel size (um)
FoVx = Nx * pixSizeObj; 
FoVy = Ny * pixSizeObj;

%Spatial frequency sampling
if mod(Nx,2)==1, dux = 1/pixSizeObj/(Nx-1); else, dux = 1/FoVx; end
if mod(Ny,2)==1, duy = 1/pixSizeObj/(Ny-1); else, duy = 1/FoVy; end

%%  ---------- 2. Initial pupil ----------
um_m = systemSetup.NA / systemSetup.lambda; % Cutoff spatial frequency [1/um]
[xg,yg] = meshgrid((-Nx/2):(Nx/2-1), (-Ny/2):(Ny/2-1));
r = sqrt(xg.^2 + yg.^2);
um_idx = um_m / min(dux,duy);
pupil0 = double(r < um_idx); %Binary pupil support
pupil0 = initPupil(pupil0, options.initialPupil);

%% ---------- 3. LED frequency shifts ----------
% Assume LED_Array, systemSetup, dux, duy are given
[idx_X, idx_Y, illuminationNA] = ...
    LEDcoord_from_array(LED_Array, '77', systemSetup, dux, duy);

%% ---------- 4. Determine reconstruction canvas size ----------
um_p = max(max(illuminationNA))/systemSetup.lambda + um_m;
disp(['synthetic NA is ', num2str(um_p*systemSetup.lambda)]);

N_objX2 = round(2*um_p/dux) * 2;
N_objX = ceil(N_objX2/Nx) * Nx;
if N_objX == Nx
    N_objX = N_objX * 2;
end
N_objY = Ny * N_objX / Nx;

%% ---------- 5. Initialization ----------
FT = @(x) fftshift(fft2(ifftshift(x)));
IFT = @(x) fftshift(ifft2(ifftshift(x)));

cen0 = round([N_objY,N_objX]/2);
O = zeros(N_objY, N_objX);
P = pupil0;

% Initialize object spectrum using the center LED
I_c = ImagesIn(:,:,sub2ind(size(LEDsUsed), y0, x0));
Os = FT(sqrt(I_c));
n1 = cen0 - floor([Ny,Nx]/2);
n2 = n1 + [Ny,Nx] - 1;
O(n1(1):n2(1), n1(2):n2(2)) = Os .* pupil0;

%%   ---------- 6. Main reconstruction loop ----------
err_curve = [];
for it = 1:options.maxIter
    for m = 1:Nimgs
        [ledY, ledX] = ind2sub(size(LEDsUsed), find(LEDsUsed));
        nX = idx_X(ledY(m), ledX(m));
        nY = idx_Y(ledY(m), ledX(m));
        cen = cen0 + [nY,nX];

        % Crop sub-spectrum and apply pupil
        Psi0 = O(cen(1)-Ny/2+1:cen(1)+Ny/2, cen(2)-Nx/2+1:cen(2)+Nx/2).*P;
        psi0 = IFT(Psi0);
        I_est = abs(psi0).^2;
        % ---- Intensity correction ----
        I_mea = ImagesIn(:,:,m);
        if it > 1 && options.IntCorr == 1
            c(ledY(m),ledX(m)) = sum(sum(sqrt(I_est))) / sum(sum(sqrt(I_mea)));
        end
        % Replace amplitude while preserving phase
        Psi = forward_project(psi0, ImagesIn(:,:,m), I_est, FT);
        dPsi = Psi - Psi0;

        % Update object and pupil (Quasi-Newton / rank-1 gradient descent)
        [O,P] = GDUpdate_rank1(O,P,dPsi,max(abs(O(:))),cen,pupil0,options.alpha,options.beta);
    end
    err_curve(end+1) = rms(I_est(:) - ImagesIn(:,:,m)(:));
end

%% ---------- 7. Outputs ----------
O_rec = IFT(O);
phase_rec = angle(O_rec);
P_rec = P;

end
