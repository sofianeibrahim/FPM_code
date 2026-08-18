function cap = capture_scan(rings, pwm_by_ring, exp_by_ring, opts)
% capture_scan_rings - 按 ring 拍摄（有样品），仅保存 RAW + 元数据
% 输入
%   rings        : {ring0, ring1, ...}，每个 ringX 是 cellstr 的 ID 列表（已按"左上→顺时针"）
%   pwm_by_ring  : 1xR cell，与 rings 一一对应，如 {'e00','g00', ...}
%   exp_by_ring  : 1xR double，与 rings 一一对应（单位 us，例如 150000）
%   opts         : 结构体（可选）
%       .cmdGap_s    (默认 0.020)
%       .settle_s    (默认 0.002)
%       .darkAvgN    (默认 4)
%       .avgPerLED   (默认 1)   % 有样品时通常 1 帧即可；需要时可做小平均
%       .save_tag    (默认 'capture_trans') % 如 'capture_BF' / 'capture_DF'
%       .save_root   (默认 <本函数目录>/Capture)
%
% 依赖：led_on, led_off, snap_shot；且 base 工作区已有 s, vid, src

% ---- 参数/默认 ----
if nargin < 4, opts = struct(); end
cmdGap_s  = get_opt(opts, 'cmdGap_s',  0.020);
settle_s  = get_opt(opts, 'settle_s',  0.002);
darkAvgN  = get_opt(opts, 'darkAvgN',  4);
avgPerLED = get_opt(opts, 'avgPerLED', 1);
save_tag  = get_opt(opts, 'save_tag',  'capture_trans');

thisDir   = fileparts(mfilename('fullpath'));
saveRoot  = get_opt(opts, 'save_root', fullfile(thisDir,'Capture'));

% ---- 取相机与串口 ----
s   = evalin('base','s');
vid = evalin('base','vid');
src = evalin('base','src');

% ---- 创建保存目录 ----
if ~exist(saveRoot,'dir'), mkdir(saveRoot); end
saveDir = make_save_dir(saveRoot, save_tag);
fprintf('Save to: %s\n', saveDir);

% ---- 暗场 ----
led_off(s, cmdGap_s);
dark = acquire_dark_sample(vid, src, darkAvgN);
imwrite(uint16(dark), fullfile(saveDir,'dark.tiff'));

% ---- 展开所有 ID（按 ring 顺序拼接）----
R = numel(rings);
assert(numel(pwm_by_ring) == R && numel(exp_by_ring) == R, ...
    'pwm_by_ring / exp_by_ring 与 rings 数量必须一致');

ids_all = {};
ring_idx_of_id = [];
for r = 1:R
    ids_r = rings{r}(:);
    ids_all = [ids_all; ids_r]; %#ok<AGROW>
    ring_idx_of_id = [ring_idx_of_id; r*ones(numel(ids_r),1)]; %#ok<AGROW>
end
N = numel(ids_all);

% ---- 相机尺寸（用于预分配）----
vr = get(vid, 'VideoResolution');   % [W H]
W  = vr(1); H = vr(2);

% ---- 元数据容器 ----
meta = struct();
meta.ids       = string(ids_all);
meta.ring_idx  = ring_idx_of_id(:);
meta.pwm       = strings(N,1);
meta.exposure  = zeros(N,1,'double');  % us
meta.timestamp = strings(N,1);
meta.darkAvgN  = darkAvgN;
meta.avgPerLED = avgPerLED;
meta.save_tag  = save_tag;

% ---- 逐 ID 采集 RAW ----
for i = 1:N
    id = ids_all{i};
    r  = ring_idx_of_id(i);

    % 设置该 ring 的曝光与 PWM
    src.ExposureTime = exp_by_ring(r);
    this_pwm = pwm_by_ring{r};

    % 点亮 -> 触发 -> （可选）多帧平均
    led_on(s, this_pwm, id, settle_s);
    if avgPerLED <= 1
        raw = snap_shot(vid, src);      % uint16 / int 类型由相机决定
        img = raw;
    else
        acc = zeros(H, W, 'double');
        for k = 1:avgPerLED
            acc = acc + double(snap_shot(vid, src));
        end
        img = uint16(acc / avgPerLED);  % 保存为 16-bit
    end
    led_off(s, cmdGap_s);

    % 保存 RAW，不做任何处理
    fpath = fullfile(saveDir, sprintf('%03d_%s.tiff', i, id));
    imwrite(uint16(img), fpath, 'Compression','none');

    % 记录元数据
    meta.pwm(i)       = string(this_pwm);
    meta.exposure(i)  = exp_by_ring(r);
    meta.timestamp(i) = string(datetime('now','Format','yyyy-MM-dd HH:mm:ss.SSS'));

    if mod(i,8)==0 || i==N
        fprintf('[%3d/%3d] %s (ring %d) saved\n', i, N, id, r);
    end
end

% ---- 结束关灯并保存 meta ----
led_off(s, cmdGap_s);

cap.save_dir = saveDir;
cap.dark     = dark;      % 也存到 mat，方便后处理读
cap.meta     = meta;

save(fullfile(saveDir,'meta.mat'), 'cap');

% （可选）再写一份 CSV 方便肉眼核对/脚本读取
try
    T = table( (1:N).', meta.ids, meta.ring_idx, meta.pwm, meta.exposure, meta.timestamp, ...
        'VariableNames', {'idx','id','ring','pwm','exposure_us','timestamp'});
    writetable(T, fullfile(saveDir,'meta.csv'));
catch
    warning('写 meta.csv 失败（非致命）。');
end
end

% --------- utils ----------
function val = get_opt(s, field, default)
if nargin < 3, default = []; end
if ~isstruct(s) || ~isfield(s, field) || isempty(s.(field))
    val = default;
else
    val = s.(field);
end
end
