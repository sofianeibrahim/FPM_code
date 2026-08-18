function flat_bank = capture_flat_bank(rings, pwm_by_ring, exp_by_ring, opts)
% capture_flat_bank_rings
% 每个 ring 的 LED 顺序按 rings{r} 的 ID 列表执行（你已按"左上→顺时针"排好）
% 输入
%   rings        : {ring0, ring1, ...}，每个 ringX 是 cellstr 的 ID 列表
%   pwm_by_ring  : 1xR cell，如 {'e00','g00', ...} —— 与 rings 一一对应
%   exp_by_ring  : 1xR double，如 [100000, 150000, ...] —— 与 rings 一一对应（单位：us）
%   opts         : 结构体（可选）
%       .cmdGap_s    (默认 0.020)
%       .settle_s    (默认 0.002)
%       .darkAvgN    (默认 4)
%       .avgPerLED   (默认 3)
%       .roi         (默认 make_center_roi_mask([H W], [], 0.60))
%       .save_root   (默认 <本函数目录>/Capture)
%       .save_tag    (默认 'flat_bank')  —— 用于区分 BF/DF，如 'flat_BF' / 'flat_DF'
%       .ref_id      (默认 '77')         —— 用于相对增益归一（g_ref = 1）
%
% 依赖：led_on, led_off, snap_shot；且工作区已有 s, vid, src

% ---- 参数/默认 ----
if nargin < 4, opts = struct(); end
cmdGap_s  = get_opt(opts, 'cmdGap_s',  0.020);
settle_s  = get_opt(opts, 'settle_s',  0.002);
darkAvgN  = get_opt(opts, 'darkAvgN',  4);
avgPerLED = get_opt(opts, 'avgPerLED', 3);
save_tag  = get_opt(opts, 'save_tag',  'flat_bank');
ref_id    = get_opt(opts, 'ref_id',    '77');

thisDir   = fileparts(mfilename('fullpath'));
saveRoot  = get_opt(opts, 'save_root', fullfile(thisDir,'Capture'));

% ---- 取相机与串口 ----
s   = evalin('base','s');      % 你的全局句柄（如需可以改成参数传入）
vid = evalin('base','vid');
src = evalin('base','src');

% ---- 创建保存目录 ----
if ~exist(saveRoot,'dir'), mkdir(saveRoot); end
saveDir = make_save_dir(saveRoot, save_tag);
fprintf('Flat save dir: %s\n', saveDir);

% ---- 暗场 ----
led_off(s, cmdGap_s);
dark = acquire_dark_sample(vid, src, darkAvgN);
imwrite(uint16(dark), fullfile(saveDir,'dark.tiff'));
pause(0.010);

% ---- ROI（若未给） ----
vr = get(vid, 'VideoResolution');   % [W H]
W  = vr(1); H = vr(2);
roi = get_opt(opts, 'roi', make_center_roi_mask([H W], [], 0.60));

% ---- 展开所有 ID（按 ring 顺序拼接）----
R = numel(rings);
assert(numel(pwm_by_ring) == R && numel(exp_by_ring) == R, ...
    'pwm_by_ring / exp_by_ring 与 rings 数量必须一致');

ids_all = {};
ring_idx_of_id = [];  % 与 ids_all 同长：记录该 ID 属于第几个 ring
for r = 1:R
    ids_r = rings{r}(:);
    ids_all = [ids_all; ids_r];
    ring_idx_of_id = [ring_idx_of_id; r*ones(numel(ids_r),1)]; %#ok<AGROW>
end
N = numel(ids_all);

% ---- 结果结构 ----
flat_bank.mode  = save_tag;    % 你可以传 'flat_BF' 或 'flat_DF'
flat_bank.dark  = dark;
flat_bank.ids   = string(ids_all);
flat_bank.files = strings(N,1);
flat_bank.meta.rings       = rings;
flat_bank.meta.pwm_by_ring = pwm_by_ring;
flat_bank.meta.exp_by_ring = exp_by_ring;

% ---- 逐 ID 拍摄 ----
m = zeros(N,1);   % 亮度统计（用于 g 估计）
for i = 1:N
    id = ids_all{i};
    r  = ring_idx_of_id(i);

    % 设置该 ring 的曝光与 PWM
    src.ExposureTime = exp_by_ring(r);
    this_pwm = pwm_by_ring{r};

    % 开灯 -> 等 -> 连拍 avgPerLED 并平均
    led_on(s, this_pwm, id, settle_s);
    acc = zeros(H, W, 'double');
    for k = 1:avgPerLED
        acc = acc + double(snap_shot(vid, src));
    end
    led_off(s, cmdGap_s);
    F = acc / avgPerLED;

    % 亮度统计（扣暗后 ROI 中值）
    Fd = double(F) - double(dark);
    Fd(Fd <= 1) = 1;
    if isempty(roi)
        m(i) = median(Fd(:));
    else
        m(i) = median(Fd(roi));
    end

    % 保存 16-bit raw flat（仍带暗电流；与之前兼容）
    fpath = fullfile(saveDir, sprintf('flat_%03d_%s.tiff', i, id));
    imwrite(uint16(F), fpath, 'Compression','none');
    flat_bank.files(i) = string(fpath);

    if mod(i,8)==0 || i==N
        fprintf('[%3d/%3d] %s (ring %d)\n', i, N, id, r);
    end
end

% ---- 相对增益估计：以 ref_id 作为参考（若存在），否则以第一帧为参考 ----
idx_ref = find(flat_bank.ids == string(ref_id), 1);
if isempty(idx_ref), idx_ref = 1; end
g = m(idx_ref) ./ m;            % g_ref = 1

flat_bank.gains.ids = flat_bank.ids;
flat_bank.gains.val = g(:);

% ---- 收尾 ----
led_off(s, cmdGap_s);
save(fullfile(saveDir, [save_tag '.mat']), 'flat_bank');

end % function

% --------- utils ----------
function val = get_opt(s, field, default)
if nargin < 3, default = []; end
if ~isstruct(s) || ~isfield(s, field) || isempty(s.(field))
    val = default;
else
    val = s.(field);
end
end
