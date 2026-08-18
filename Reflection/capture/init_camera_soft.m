function [vid,src] = init_camera_soft(exp_us, gain)
%INIT_CAMERA_SOFT  初始化相机 (Software Trigger, 单色模式)
%   vid = init_camera_soft(exp_us, gain)
%   exp_us: 曝光时间 (微秒)，[] 表示不设置
%   gain  : 增益，[] 表示不设置
%
%   用法:
%       vid = init_camera_soft(20000, 0);  % 曝光20ms，增益0
%       trigger(vid); I = getdata(vid,1); % 触发取一帧

    imaqreset;  % 重置采集硬件

    % -- 创建视频输入对象 (gentl, 单色16位) --
    vid = videoinput('gentl', 1, 'Mono16');
    src = getselectedsource(vid);

    % -- 触发配置 (Software Trigger) --
    triggerconfig(vid, 'hardware','DeviceSpecific','DeviceSpecific');
    src.TriggerMode     = 'Off';           % 修改参数前先关
    src.TriggerSelector = 'FrameStart';
    src.TriggerSource   = 'Software';
    vid.FramesPerTrigger = 1;              % 每次触发采一帧
    vid.TriggerRepeat    = Inf;            % start 一次，可多次触发
    vid.LoggingMode      = 'memory';
    vid.ReturnedColorSpace = 'grayscale';

    % -- 关闭自动曝光/增益 --
    if isprop(src,'ExposureAuto'), src.ExposureAuto = 'Off'; end
    if isprop(src,'GainAuto'),     src.GainAuto     = 'Off'; end

    % -- 关闭 Gamma, BlackLevel --
    if isprop(src,'GammaEnable'),  src.GammaEnable = false; end
    if isprop(src,'BlackLevel'),   src.BlackLevel  = 0;     end

    % -- 曝光上限 --
    if isprop(src, 'AutoExposureUpperLimit')
        src.AutoExposureUpperLimit = 32000000; % 32s 上限 (µs)
    end

    % -- 设置曝光/增益 --
    if ~isempty(exp_us) && isprop(src,'ExposureTime')
        src.ExposureTime = exp_us;   % 单位 µs
    end
    if ~isempty(gain) && isprop(src,'Gain')
        src.Gain = gain;
    end

    % -- 开启 TriggerMode --
    src.TriggerMode = 'On';
    vid.Timeout     = 3;

    % -- 启动采集引擎 (等待 trigger) --
    start(vid);

    disp('📷 Camera ready (software trigger).');
end
