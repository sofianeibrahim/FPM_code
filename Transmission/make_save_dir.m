function saveDir = make_save_dir(saveRoot, save_tag)
%MAKE_SAVE_DIR  在 saveRoot 下创建带时间戳且唯一的保存目录
% 用法:
%   saveDir = make_save_dir(saveRoot, save_tag);
% 例子:
%   make_save_dir('D:\data', 'capture_trans')
%
% 结果示例:
%   D:\data\capture_trans_20250923_143501
%   如果已存在则自动加 _001/_002...

    if nargin < 1 || isempty(saveRoot), saveRoot = pwd; end
    if nargin < 2 || isempty(save_tag),  save_tag  = 'capture'; end

    % 转成 char，兼容 string 输入
    if ~ischar(saveRoot), saveRoot = char(saveRoot); end
    if ~ischar(save_tag), save_tag  = char(save_tag);  end

    % 根目录不存在就创建
    if ~exist(saveRoot, 'dir')
        mkdir(saveRoot);
    end

    % 安全的标签名（去掉奇怪字符）
    

    % 基本目录名：标签 + 时间戳
  
    baseName = sprintf('%s_%s', save_tag);
    saveDir  = fullfile(saveRoot, baseName);

    % 若已存在（极少见），递增后缀
    k = 1;
    while exist(saveDir, 'dir')
        saveDir = fullfile(saveRoot, sprintf('%s_%03d', baseName, k));
        k = k + 1;
    end

    % 创建并返回
    mkdir(saveDir);
end
