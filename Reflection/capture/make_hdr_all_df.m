clc;
clear;

%% =========================================================
%% BF rings
%% =========================================================

ring0 = {'16'};
ring1 = {'15','14','13','12','11'};
ring2 = {'10','9','8','7','6','5','4','3','2','1'};

rings_bf = {ring0,ring1,ring2};

%% =========================================================
%% DF rings
%% =========================================================

ring_df0 = { ...
    '10','9','8','7','6','5','4','3','2','1'};

ring_df1 = { ...
    '25','24','23','22','21',...
    '20','19','18','17','16',...
    '15','14','13','12','11'};


ring_df2 = { ...
    '18','17','16','15','14','13','12','11','10',...
    '9','8','7','6','5','4','3','2','1'};


ring_df3 = { ...
    '43','42','41','40','39','38','37','36','35',...
    '34','33','32','31','30','29','28','27','26',...
    '25','24','23','22','21','20','19'};


ring_df4 = { ...
    '80','79','78','77','76','75','74','73','72',...
    '71','70','69','68','67','66','65','64','63',...
    '62','61','60','59','58','57','56','55','54',...
    '53','52','51','50','49','48','47','46','45','44'};

rings_df = { ...
    ring_df0,...
    ring_df1,...
    ring_df2,...
    ring_df3,...
    ring_df4};

%% =========================================================
%% HDR source folders
%% =========================================================

sourceFolder = ...
"D:\Sofiane_data\Reflection\capture_20260804_090220";


subFolders = { ...
    'HDR_MIN',...
    'HDR_MID',...
    'HDR_MAX'};

folders = fullfile(sourceFolder,subFolders);

%% =========================================================
%% Output folders
%% =========================================================

outFolderBF = fullfile(sourceFolder,'HDR_BF');
outFolderDF = fullfile(sourceFolder,'HDR_DF');

if ~exist(outFolderBF,'dir')
    mkdir(outFolderBF);
end

if ~exist(outFolderDF,'dir')
    mkdir(outFolderDF);
end

fprintf('\nHDR output folders:\n');
fprintf('%s\n',outFolderBF);
fprintf('%s\n\n',outFolderDF);

%% =========================================================
%% Exposure values
%% MUST MATCH acquisition
%% =========================================================

%% BF exposures

exp_bf_min = [500000 700000 1000000] * 1e-6;
exp_bf_mid = [1000000 1300000 1600000] * 1e-6;
exp_bf_max = [1800000 2200000 2600000] * 1e-6;

%% DF exposures

exp_df_min = [1200000 1400000 1600000 2900000 2200000] * 1e-6;
exp_df_mid = [1800000 2000000 2200000 2500000 2800000] * 1e-6;
exp_df_max = [3000000 3200000 3400000 3700000 4000000] * 1e-6;

%% =========================================================
%% Build LED -> ring maps
%% =========================================================

led2ring_bf = containers.Map;

for r = 1:numel(rings_bf)

    ids = rings_bf{r};

    for k = 1:numel(ids)

        led2ring_bf(lower(ids{k})) = r;

    end
end

led2ring_df = containers.Map;

for r = 1:numel(rings_df)

    ids = rings_df{r};

    for k = 1:numel(ids)

        led2ring_df(lower(ids{k})) = r;

    end
end

%% =========================================================
%% Use first folder as reference
%% =========================================================

L = dir(fullfile(folders{1},'*.tiff'));

fprintf('Reference folder:\n%s\n',folders{1});
fprintf('TIFF files found: %d\n\n',numel(L));

nImgs = numel(L);

%% =========================================================
%% HDR reconstruction
%% =========================================================

for i = 1:nImgs

    fname = L(i).name;

    fprintf('\n====================================\n');
    fprintf('[%d/%d] %s\n',i,nImgs,fname);

    %% =====================================================
    %% Parse filename
    %% =====================================================

    % Example:
    % BF_001_LED16_EXP500000.tiff

    parts = split(fname,{'_','.'});

    modeStr = parts{1};

    ledStr = parts{3};

    ledID = lower(erase(ledStr,'LED'));

    fprintf('Mode = %s | LED = %s\n',modeStr,ledID);

    %% =====================================================
    %% Ring + exposure selection
    %% =====================================================

    if strcmpi(modeStr,'BF')

        if ~isKey(led2ring_bf,ledID)

            warning('Unknown BF LED');
            continue;

        end

        r = led2ring_bf(ledID);

        times = [ ...
            exp_bf_min(r),...
            exp_bf_mid(r),...
            exp_bf_max(r)];

        outFolder = outFolderBF;

    elseif strcmpi(modeStr,'DF')

        if ~isKey(led2ring_df,ledID)

            warning('Unknown DF LED');
            continue;

        end

        r = led2ring_df(ledID);

        times = [ ...
            exp_df_min(r),...
            exp_df_mid(r),...
            exp_df_max(r)];

        outFolder = outFolderDF;

    else

        warning('Unknown mode');
        continue;

    end

    disp(times)

    %% =====================================================
    %% Recover corresponding HDR files
    %% =====================================================

    files = cell(1,numel(folders));

    for f = 1:numel(folders)

        currentFolder = folders{f};

        pattern = sprintf('%s_*_LED%s_*.tiff', ...
            modeStr,...
            ledID);

        D = dir(fullfile(currentFolder,pattern));

        if isempty(D)

            warning('Missing file in: %s',currentFolder);
            continue;

        end

        files{f} = fullfile(currentFolder,D(1).name);

    end

    %% remove empty
    files = files(~cellfun(@isempty,files));

    disp(files')

    %% =====================================================
    %% Read images
    %% =====================================================

    imgs = cell(size(files));

    for k = 1:numel(files)

        imgs{k} = double(imread(files{k}));

    end

    imgs = cat(3,imgs{:});

    %% =====================================================
    %% Exposure normalization
    %% =====================================================

    for k = 1:numel(times)

        imgs(:,:,k) = imgs(:,:,k) ./ times(k);

    end

    %% =====================================================
    %% HDR merge
    %% =====================================================

    hdr = median(imgs,3);

    %% =====================================================
    %% Robust normalization
    %% =====================================================

    hdr = hdr - min(hdr(:));

    mx = max(hdr(:));

    fprintf('HDR max = %f\n',mx);

    if mx <= 0

        warning('Empty HDR image');
        continue;

    end

    hdr = hdr ./ mx;

    hdr(isnan(hdr)) = 0;
    hdr(isinf(hdr)) = 0;

    %% =====================================================
    %% Save
    %% =====================================================

    outName = fullfile( ...
        outFolder,...
        sprintf('%s_HDR_LED%s.tiff', ...
        modeStr,...
        ledID));

    fprintf('Saving to:\n%s\n',outName);

    try

        imwrite( ...
            uint16(hdr * 65535),...
            outName,...
            'Compression','none');

        fprintf('Saved OK\n');

    catch ME

        fprintf('SAVE FAILED\n');
        disp(ME.message);

    end

end

fprintf('\n====================================\n');
fprintf('HDR reconstruction completed.\n');
fprintf('====================================\n');