function pupil = initPupil(pupil0, type)
% INITPUPIL  Initialize the pupil function
%
% Inputs:
%   pupil0  - Base pupil mask (binary circular aperture defining NA support)
%   type    - 1 = ones (fully open / flat amplitude)
%             2 = Tukey window (edge smoothing)
%             3 = Gaussian window (edge tapering)
%
% Output:
%   pupil   - Initialized pupil (complex-valued, amplitude distribution)

[ny, nx] = size(pupil0);

switch type
    case 1  % ones
        pupil = pupil0;

    case 2  % Tukey window
        % Define radius
        [x,y] = meshgrid(-nx/2:nx/2-1, -ny/2:ny/2-1);
        r = sqrt(x.^2 + y.^2);
        % Tukey window: convert 1D window to 2D (radial)
        L = round(min(nx,ny)/2);
        win = tukeywin(L*2,0.25); % α=0.25
        win = win(L+1:end);       % half window (radial part)
        win2D = interp1(0:L-1, win, r(r<=L-1), 'linear', 0);
        mask = zeros(size(r));
        mask(r<=L-1) = win2D;
        pupil = pupil0 .* mask;

    case 3  % Gaussian window
        % Based on the current pupil diameter
        dx = sum(pupil0(round(end/2),:));
        dy = sum(pupil0(:,round(end/2)));
        gaussX = gausswin(dx,0.25);
        gaussY = gausswin(dy,0.25);
        pup = gaussY * gaussX';
        pup = padarray(pup, [round((ny-dy)/2), round((nx-dx)/2)], 0, 'both');
        pupil = pupil0 .* pup(1:ny,1:nx);

    otherwise
        error('Unknown pupil type (use 1=ones, 2=tukey, 3=gauss)');
end

end
