function [bestScore, bestImg] = focus_assist_manual(vid, method, roi)
% 只显示实时图像与分数曲线（无方向提示）
% vid    : videoinput（software trigger）
% method : 'laplacian' | 'tenengrad' | 'variance'
% roi    : [] 或 [x y w h]
% 返回：bestScore（最大清晰度），bestImg（对应原图 uint16）

if nargin < 2 || isempty(method), method = 'laplacian'; end
if nargin < 3, roi = []; end
src = getselectedsource(vid);

% ── 图1：实时图像（统一 16-bit 显示） ──
hFigImg = figure('Name','Focus (Q 退出，R 重置)', ...
    'NumberTitle','off', 'KeyPressFcn',@(h,e)keyCB(h,e));
setappdata(hFigImg,'quit',false);
setappdata(hFigImg,'reset',false);

hAx1 = axes('Parent',hFigImg);
% 用 imagesc + uint16，自动缩放更稳；也可以 imshow(...,[])
hIm  = imagesc(hAx1, zeros(2,'uint16')); 
axis(hAx1,'image'); colormap(hAx1,gray(256)); hold(hAx1,'on');
set(hAx1,'CLimMode','auto');                        % 让 CData 更新时自动调窗宽

hRoi = rectangle(hAx1,'Position',[1 1 10 10], ...
    'EdgeColor','y','LineWidth',1.5,'Visible','off');

% ── 图2：分数曲线 ──
hFigScore = figure('Name','Focus score','NumberTitle','off');
hAx2  = axes('Parent',hFigScore); hold(hAx2,'on'); grid(hAx2,'on');
hLine = plot(hAx2,nan,nan,'-','LineWidth',1.5);
hPeak = plot(hAx2,nan,nan,'ro','MarkerFaceColor','r');
xlabel(hAx2,'Frame'); ylabel(hAx2,'Score');
xlim(hAx2,[0 100]); set(hAx2,'YLimMode','auto');

% 状态
scores = [];
bestScore = -Inf; bestImg = [];
frameId = 0;

% ── 预处理参数（16位友好） ──
usePreproc = true;   % 看原图就设 false
pp = struct( ...
    'doMedian',true,        'medianK',3, ...
    'doGauss',true,         'gaussSigma',0.7, ...
    'doBandpass',true,      'hpSigma',10, ...
    'doNormalize',true,     'normPercentile',98, ...  % 16位更适合高分位
    'temporalAlpha',0.2, ...                         % 0 关闭；0.2~0.4 稳
    'viewFiltered',true, ...
    'showAutoScale',true,   'showPercentile',[1 99]); % 只影响显示，不改评分

% 主循环
while ishandle(hFigImg) && ~getappdata(hFigImg,'quit')

    if getappdata(hFigImg,'reset')
        scores = []; bestScore = -Inf; bestImg = []; frameId = 0;
        setappdata(hFigImg,'reset',false);
        cla(hAx2); hold(hAx2,'on'); grid(hAx2,'on');
        hLine = plot(hAx2,nan,nan,'-','LineWidth',1.5);
        hPeak = plot(hAx2,nan,nan,'ro','MarkerFaceColor','r');
        xlim(hAx2,[0 100]); set(hAx2,'YLimMode','auto');
        preproc_for_focus('reset');                 % 清 EMA
    end

    % 采一帧（Mono16 / uint16）
    executeCommand(src,'TriggerSoftware');
    img = getdata(vid,1);                           % uint16（14-bit 左对齐）

    % 预处理（评分链：double[0,1]；显示链：uint16）
    if usePreproc
        [imgScore, imgShow] = preproc_for_focus(img, roi, pp);
    else
        % 不预处理：评分用 double[0,1]；显示用 16 位自拉伸
        if ~isempty(roi), imgR = imcrop(img,roi); else, imgR = img; end
        imgScore = im2double(imgR);
        imgShow  = im2uint16(mat2gray(imgR));       % 显示用 16位
    end

    % 显示
    imgDisp = im2uint16(mat2gray(img));                  % 全幅显示图：16位 + 自动拉伸
    set(hIm,'CData', imgDisp); set(hAx1,'CLimMode','auto');                   % imagesc + CLimMode auto
    if ~isempty(roi), set(hRoi,'Position',roi,'Visible','on');
    else,             set(hRoi,'Visible','off'); end

    % 评分
    score = focus_metric(imgScore, method);         % 不再乘 1e4，直接用原值

    % 统计
    frameId = frameId + 1;
    scores(frameId) = score; %#ok<AGROW>
    if score > bestScore
        bestScore = score;
        bestImg   = img;                            % 保留原始 uint16
    end

    % 曲线
    set(hLine,'XData',1:frameId,'YData',scores);
    [mx,mxIdx] = max(scores);
    set(hPeak,'XData',mxIdx,'YData',mx);

    % 动态 X 轴
    xLimNow = get(hAx2,'XLim');
    if frameId > xLimNow(2)-10, xlim(hAx2,[0, max(100, frameId+10)]); end

    % 标题
    title(hAx1, sprintf('score = %.3g   |   best = %.3g   (Q退出/R重置)', ...
        score, bestScore));

    drawnow limitrate;
end

    function keyCB(h,evt)
        switch lower(evt.Key)
            case 'q', setappdata(h,'quit',true);
            case 'r', setappdata(h,'reset',true);
        end
    end
end
