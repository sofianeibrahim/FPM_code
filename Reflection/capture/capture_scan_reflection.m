function cap = capture_scan_reflection( ...
    nstrip_bf,...
    nstrip_df,...
    rings_bf,...
    rings_df,...
    exp_by_ring_bf,...
    exp_by_ring_df,...
    gain,...
    opts)

%% =========================================================
%% Options
%% =========================================================

if nargin < 8
    opts = struct();
end

avgPerLED  = get_opt(opts,'avgPerLED',1);
brightness = get_opt(opts,'brightness',0.6);
save_tag   = get_opt(opts,'save_tag','reflection');
save_root  = get_opt(opts,'save_root',fullfile(pwd,'Capture'));

assert(isnumeric(exp_by_ring_bf),...
    'exp_by_ring_bf must be numeric');

assert(isnumeric(exp_by_ring_df),...
    'exp_by_ring_df must be numeric');

%% =========================================================
%% NeoPixel brightness
%% =========================================================

nstrip_bf.Brightness = brightness;
nstrip_df.Brightness = brightness;

%% =========================================================
%% Camera init
%% =========================================================

init_exp = exp_by_ring_bf(1);

[vid,src] = init_camera_soft(init_exp,gain);

%% =========================================================
%% Save directory
%% =========================================================

if ~exist(save_root,'dir')
    mkdir(save_root);
end

%ts = datestr(now,'yyyymmdd_HHMMSS');

%saveDir = fullfile(save_root,[save_tag '_' ts]);
saveDir = fullfile(save_root,save_tag);
mkdir(saveDir);

fprintf('Saving to:\n%s\n\n',saveDir);

%% =========================================================
%% Flatten BF rings
%% =========================================================

ids_bf  = {};
ring_bf = [];

for r = 1:numel(rings_bf)

    ids_r = rings_bf{r}(:);

    ids_bf = [ids_bf; ids_r];

    ring_bf = [ring_bf; ...
        r*ones(numel(ids_r),1)];

end

%% =========================================================
%% Flatten DF rings
%% =========================================================

ids_df  = {};
ring_df = [];

for r = 1:numel(rings_df)

    ids_r = rings_df{r}(:);

    ids_df = [ids_df; ids_r];

    ring_df = [ring_df; ...
        r*ones(numel(ids_r),1)];

end

%% =========================================================
%% Image size
%% =========================================================

vr = get(vid,'VideoResolution');

W = vr(1);
H = vr(2);

%% =========================================================
%% Metadata
%% =========================================================

meta = struct();

meta.bf.exposure_by_ring = exp_by_ring_bf;
meta.df.exposure_by_ring = exp_by_ring_df;

%% =========================================================
%% BF acquisition
%% =========================================================

fprintf('\n====================================\n');
fprintf('Reflection / BF acquisition\n');
fprintf('====================================\n');

Nbf = numel(ids_bf);

meta.bf.ids = string(ids_bf);
meta.bf.ring = ring_bf;
meta.bf.exposure = zeros(Nbf,1);
meta.bf.timestamp = strings(Nbf,1);

for i = 1:Nbf

    led_id = str2double(ids_bf{i});

    current_ring = ring_bf(i);

    current_exp = exp_by_ring_bf(current_ring);

    %% Set exposure
    src.ExposureTime = current_exp;

    pause(0.05);

    %% LED ON
    writeColor(nstrip_bf,led_id,'red');

    pause(0.1);

    %% Capture
    img = acquire_avg( ...
        vid,...
        src,...
        avgPerLED,...
        H,...
        W);

    %% LED OFF
    writeColor(nstrip_bf,led_id,[0 0 0]);

    %% Save
    fname = fullfile( ...
        saveDir,...
        sprintf( ...
        'BF_%03d_LED%s_EXP%d.tiff',...
        i,...
        ids_bf{i},...
        current_exp));

    imwrite(uint16(img),...
        fname,...
        'Compression','none');

    %% Metadata
    meta.bf.exposure(i) = current_exp;

    meta.bf.timestamp(i) = ...
        string(datetime('now'));

    fprintf( ...
        '[BF %d/%d] LED %s | EXP %d us\n',...
        i,...
        Nbf,...
        ids_bf{i},...
        current_exp);

end

%% =========================================================
%% DF acquisition
%% =========================================================

fprintf('\n====================================\n');
fprintf('Darkfield acquisition\n');
fprintf('====================================\n');

Ndf = numel(ids_df);

meta.df.ids = string(ids_df);
meta.df.ring = ring_df;
meta.df.exposure = zeros(Ndf,1);
meta.df.timestamp = strings(Ndf,1);

for i = 1:Ndf

    led_id = str2double(ids_df{i});

    current_ring = ring_df(i);

    current_exp = exp_by_ring_df(current_ring);

    %% Set exposure
    src.ExposureTime = current_exp;

    pause(0.05);

    %% LED ON
    writeColor(nstrip_df,led_id,'red');

    pause(0.1);

    %% Capture
    img = acquire_avg( ...
        vid,...
        src,...
        avgPerLED,...
        H,...
        W);

    %% LED OFF
    writeColor(nstrip_df,led_id,[0 0 0]);

    %% Save
    fname = fullfile( ...
        saveDir,...
        sprintf( ...
        'DF_%03d_LED%s_EXP%d.tiff',...
        i,...
        ids_df{i},...
        current_exp));

    imwrite(uint16(img),...
        fname,...
        'Compression','none');

    %% Metadata
    meta.df.exposure(i) = current_exp;

    meta.df.timestamp(i) = ...
        string(datetime('now'));

    fprintf( ...
        '[DF %d/%d] LED %s | EXP %d us\n',...
        i,...
        Ndf,...
        ids_df{i},...
        current_exp);

end

%% =========================================================
%% ALL OFF
%% =========================================================

for n = 1:16
    writeColor(nstrip_bf,n,[0 0 0]);
end

for n = 1:25
    writeColor(nstrip_df,n,[0 0 0]);
end

%% =========================================================
%% Save metadata
%% =========================================================

cap.save_dir = saveDir;
cap.meta = meta;

save(fullfile(saveDir,'meta.mat'),'cap');

fprintf('\nCapture completed.\n');

end

%% =========================================================
%% Helper functions
%% =========================================================

function img = acquire_avg( ...
    vid,...
    src,...
    avgPerLED,...
    H,...
    W)

if avgPerLED == 1

    img = snap_shot(vid,src);

else

    acc = zeros(H,W,'double');

    for k = 1:avgPerLED

        acc = acc + ...
            double(snap_shot(vid,src));

    end

    img = uint16(acc / avgPerLED);

end

end

function val = get_opt(s,field,default)

if ~isfield(s,field)

    val = default;

else

    val = s.(field);

end

end