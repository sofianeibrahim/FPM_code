function Psi = forward_project(psi0, Imea, Iest, FT)
% FORWARD_PROJECT  Amplitude replacement (single-LED version)
%
% Inputs:
%   psi0  - Current estimated complex field (spatial domain)
%   Imea  - Measured intensity image (spatial domain)
%   Iest  - Current estimated intensity (spatial domain)
%   FT    - Fourier transform operator
%           @(x) fftshift(fft2(ifftshift(x)))
%
% Output:
%   Psi   - Complex field after amplitude replacement (Fourier domain)

% Avoid division by zero
denom = sqrt(Iest) + eps;

% Replace amplitude with measured intensity, keep phase unchanged
psi_updated = sqrt(Imea) .* psi0 ./ denom;

%  Return to Fourier domain
Psi = FT(psi_updated);

end
