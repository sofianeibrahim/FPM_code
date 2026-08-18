%% 
function [O,P] = GDUpdate_rank1(O,P,dpsi,Omax,cen,Ps,alpha,beta)
%GDUPDATE_RANK1 Gradient descent update for FPM (Quasi-Newton style)
%
%   Inputs:
%       O     - current object spectrum estimate (2D big canvas)
%       P     - current pupil estimate (subregion size)
%       dpsi  - update term (ΔΨ = Ψ - Ψ0), same size as P
%       Omax  - normalization factor (max amplitude of O)
%       cen   - [y,x] center index of current pupil region in O
%       Ps    - pupil support mask (e.g. NA circular support)
%       alpha - regularization parameter for object update
%       beta  - regularization parameter for pupil update
%
%   Outputs:
%       O     - updated object spectrum
%       P     - updated pupil

% pupil patch size
Np = size(P);

% crop current subregion of O
n1 = cen - floor(Np/2);
n2 = n1 + Np - 1;
O1 = O(n1(1):n2(1), n1(2):n2(2));

% ---- update O subregion ----
O(n1(1):n2(1), n1(2):n2(2)) = O1 + ...
    (abs(P).*conj(P)).*dpsi ./ (abs(P).^2 + alpha) / max(abs(P(:)));

% ---- update P ----
P = P + (abs(O1).*conj(O1)).*dpsi ./ (abs(O1).^2 + beta) / Omax .* Ps;

end
