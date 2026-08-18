function [imgScore, imgShow] = preproc_for_focus(img, roi, pp)
% Used only for focus-related preprocessing;
% imgScore: double in [0,1]; imgShow: uint16
persistent ema
% ---- reset (compatible with char / string input) ----
if (ischar(img) && strcmpi(img,'reset')) || (isstring(img) && img=="reset")
    ema = []; imgScore = []; imgShow = []; return
end

if nargin < 3 || isempty(pp), pp = struct; end
def = struct('doMedian',true,'medianK',3,'doGauss',true,'gaussSigma',0.7, ...
             'doBandpass',true,'hpSigma',10,'hpMaxKernel',129, ...
             'doNormalize',true,'normPercentile',98,'temporalAlpha',0.2, ...
             'viewFiltered',true,'showAutoScale',true,'showPercentile',[1 99], ...
             'fastStretch',false);   % <-- NEW: approximate fast contrast stretching
pp = filldef(pp,def);

% ---- ROI & boundary protection ----
if ~isempty(roi)
    [H,W] = size(img);
    x = max(1, min(W, round(roi(1))));
    y = max(1, min(H, round(roi(2))));
    w = max(1, round(roi(3)));  h = max(1, round(roi(4)));
    x2 = min(W, x+w-1);  y2 = min(H, y+h-1);
    imgR0 = img(y:y2, x:x2);
else
    imgR0 = img;
end

% ---- 到 double[0,1] ----
imgR = im2double(imgR0);

% ---- 时域 EMA ----
if pp.temporalAlpha > 0
    if isempty(ema) || any(size(ema) ~= size(imgR)), ema = imgR; end
    ema  = pp.temporalAlpha*imgR + (1-pp.temporalAlpha)*ema;
    imgR = ema;
end

% ---- 空域去噪 ----
if pp.doMedian && pp.medianK >= 3
    imgR = medfilt2(imgR, [pp.medianK pp.medianK], 'symmetric');
end
if pp.doGauss && pp.gaussSigma > 0
    imgR = imgaussfilt(imgR, pp.gaussSigma, 'FilterDomain','spatial');
end 

% ---- 大核高通（照明去除）----
if pp.doBandpass && pp.hpSigma > 0
    ksz = max(3, 2*ceil(3*pp.hpSigma)+1);
    ksz = min(ksz, pp.hpMaxKernel);                 % 限制超大核
    low = imgaussfilt(imgR, pp.hpSigma, 'FilterDomain','spatial', 'FilterSize', ksz);
    imgR = imgR - low;
    imgR = imgR - min(imgR(:));
    imgR = imgR / max(eps, max(imgR(:)));
end

% ---- 帧间亮度归一化（评分链）----
if pp.doNormalize
    if pp.fastStretch
        % 近似百分位（更快）
        lim = stretchlim(imgR, [pp.showPercentile(1) pp.showPercentile(2)]/100);
        p = lim(2);
    else
        p = prctile(imgR(:), pp.normPercentile);
    end
    if p > 0, imgR = imgR / p; end
    imgR = max(0, min(1, imgR));
end

imgScore = imgR;  % 给 focus_metric 用

% ---- 显示链 ----
if pp.viewFiltered, showD = imgR; else, showD = im2double(imgR0); end
if pp.showAutoScale
    if pp.fastStretch
        lim   = stretchlim(showD, pp.showPercentile/100);
        showD = imadjust(showD, lim, []);
    else
        pr    = prctile(showD(:), pp.showPercentile);
        showD = min(max(showD, pr(1)), pr(2));
        showD = (showD - pr(1)) / max(eps, pr(2)-pr(1));
    end
else
    showD = max(0, min(1, showD));
end
imgShow = im2uint16(showD);
end

function s = filldef(s, d)
fn = fieldnames(d);
for i=1:numel(fn), f=fn{i}; if ~isfield(s,f) || isempty(s.(f)), s.(f)=d.(f); end, end
end
