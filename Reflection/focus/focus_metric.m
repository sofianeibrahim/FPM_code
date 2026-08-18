function s = focus_metric(I, method, opts)
% I: 任意类型，灰度图；method: 'laplacian'|'tenengrad'|'variance'|'brenner'|'normvar'
% opts.gauss_sigma  (默认0)  预平滑σ，0表示不平滑
% opts.roi          (默认[]) [x y w h]，为空表示整幅
% opts.eps          (默认1e-12) 防止除零

if nargin<3, opts = struct(); end
gs   = getf(opts,'gauss_sigma',0);
roi  = getf(opts,'roi',[]);
eps0 = getf(opts,'eps',1e-12);

% ---- 统一到 double[0,1] ----
if ~isa(I,'double'), I = double(I); end
I = I - min(I(:));
mx = max(I(:));
if mx>0, I = I./mx; end

% ---- ROI ----
if ~isempty(roi)
    x=roi(1); y=roi(2); w=roi(3); h=roi(4);
    I = I(y:y+h-1, x:x+w-1);
end

% ---- 预平滑 ----
if gs>0
    h = fspecial('gaussian', max(3,2*ceil(3*gs)+1), gs);
    I = imfilter(I, h, 'replicate', 'conv');
end

switch lower(method)
    case 'laplacian'      % 拉普拉斯方差
        K = [0 -1 0; -1 4 -1; 0 -1 0];
        L = imfilter(I, K, 'replicate', 'conv');
        s = var(L(:), 1);

    case 'tenengrad'      % Sobel 梯度能量
        [Gx,Gy] = imgradientxy(I, 'sobel');
        s = mean(Gx(:).^2 + Gy(:).^2);

    case 'variance'       % 直接方差（受亮度影响较大）
        s = var(I(:), 1);

    case 'normvar'        % 归一化方差：var(I)/mean(I)^2，抗亮度变化
        mu = mean(I(:)) + eps0;
        s  = var(I(:),1) / (mu*mu);

    case 'brenner'        % Brenner 聚焦度（水平+垂直二阶差分）
        Ix = I(:,3:end) - I(:,1:end-2);
        Iy = I(3:end,:) - I(1:end-2,:);
        s  = (mean(Ix(:).^2) + mean(Iy(:).^2))/2;

    otherwise
        error('Unknown method: %s', method);
end
end

function v = getf(s, k, d)
if isfield(s,k), v = s.(k); else, v = d; end
end

