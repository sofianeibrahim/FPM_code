function roi = make_center_roi_mask(sz, roi_size, frac)
%MAKE_CENTER_ROI_MASK  在图像中心生成 ROI 掩膜或矩形
% 用法:
%   roi = make_center_roi_mask([H W], [], 0.6);
%       → 生成一个中心 60% 大小的矩形 ROI，返回 [x y w h]
%
%   roi = make_center_roi_mask([H W], [h w], []);
%       → 按给定尺寸生成矩形 ROI
%
% 输入:
%   sz       : [H W] 图像尺寸
%   roi_size : [h w] ROI 大小（可以为空）
%   frac     : ROI 占比（0~1），如果 roi_size 为空，就用 frac*sz
%
% 输出:
%   roi      : [x y w h]，imcrop 等函数可直接用

H = sz(1);
W = sz(2);

if ~isempty(roi_size)
    h = roi_size(1);
    w = roi_size(2);
elseif ~isempty(frac)
    h = round(H * frac);
    w = round(W * frac);
else
    error('必须指定 roi_size 或 frac');
end

% 左上角坐标
x = floor((W - w)/2) + 1;
y = floor((H - h)/2) + 1;

roi = [x, y, w, h];
end
