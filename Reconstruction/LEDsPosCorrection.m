function [idx_X, idx_Y] = LEDsPosCorrection(O, P, I_mea, m, idx_X, idx_Y, cen0, mx, options, c,Ny, Nx,IFT)

% LED position correction for a 1D LED array (fast method)
% Inputs:
%   O, P  - Current object spectrum and pupil function
%  I_mea - Measured image of the current LED
%   m           - Index of the current LED (1...N)
%   idx_X, idx_Y - Frequency indices of all LEDs
%   cen0  - Center position (reference point in Fourier domain)
%    mx    - Maximum search range for position offset
%    options, c - Other options (intensity correction coefficient)
% --- 初始位置 ---
cen = cen0 + [idx_Y(m), idx_X(m)];

%  --- Initial position ---
if options.useGPU == 1
    Err = gpuArray(zeros(2*mx+1));
else
    Err = zeros(2*mx+1);
end

% --- Measured image amplitude ---
psi_mea = sqrt(I_mea * c(m));

%--- Initial search position ---
xcorr = mx+1; 
ycorr = mx+1;
cen_corr = cen;

% Radius r, progressively refined search
r = 2;
cond = 0;

while cond ~= 1
    for x = 1:2*r+1
        for y = 1:2*r+1
            xx = xcorr - r - 1 + x;
            yy = ycorr - r - 1 + y;
            if any([xx < 1, yy < 1, xx > 2*mx+1, yy > 2*mx+1])
                cond = 1;
                break
            end
            if Err(yy,xx)==0
                cen_tmp(2) = cen_corr(2) - r - 1 + x;
                cen_tmp(1) = cen_corr(1) - r - 1 + y;
                n1r = cen_tmp(1) - floor(Ny/2);
                n2r = n1r + Ny - 1;
                n1c = cen_tmp(2) - floor(Nx/2);
                n2c = n1c + Nx - 1;
                Psi0 = O(n1r:n2r, n1c:n2c) .* P;
                psi0 = abs(IFT(Psi0));
                Err(yy,xx) = rms(rms(psi0-psi_mea));
            end
        end
        if cond == 1
            break
        end
    end

    % Find the optimal point
    [ym,xm] = find(Err==min(Err(Err>0)));
    cen_corr2 = gather(cen + [ym,xm] - [ycorr,xcorr]);

    if isequal(cen_corr, cen_corr2)
        cond = 1;
    end

    cen_corr = cen_corr2;
    xcorr = xm;
    ycorr = ym;
end

% update idx_X, idx_Y
nYc = cen_corr(1) - cen0(1);
nXc = cen_corr(2) - cen0(2);
idx_X(m) = nXc;
idx_Y(m) = nYc;

end
