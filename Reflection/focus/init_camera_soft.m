function vid = init_camera_soft(exp_us, gain)
%INIT_CAMERA_SOFT  Initialize Camera (Software Trigger, Monochrome Mode)
%   vid = init_camera_soft(exp_us, gain)
%   exp_us: Exposure time (microseconds), [] means do not set
%   gain  : Gain, [] means do not set
%
%   Usage:
%       vid = init_camera_soft(20000, 0);  % Exposure 20ms, Gain 0
%       trigger(vid); I = getdata(vid,1); % Trigger to capture one frame
    imaqreset;  % Reset acquisition hardware
    % -- Create video input object (GenTL, Mono 16-bit) --
    %hwInfo = imaqhwinfo('gige');
    hwInfo = imaqhwinfo('gentl');
    deviceIDs = hwInfo.DeviceIDs;
    vid = videoinput('gentl', deviceIDs{1}, 'Mono16');
    %vid = videoinput('gentl', 1, 'Mono16');
    src = getselectedsource(vid);
    % -- Trigger configuration (Software Trigger) --
    triggerconfig(vid, 'hardware','DeviceSpecific','DeviceSpecific');
    src.TriggerMode     = 'Off';           % Turn off before modifying parameters
    src.TriggerSelector = 'FrameStart';
    src.TriggerSource   = 'Software';
    vid.FramesPerTrigger = 1;              % Capture one frame per trigger
    vid.TriggerRepeat    = Inf;            % Start once, allow multiple triggers
    vid.LoggingMode      = 'memory';
    vid.ReturnedColorSpace = 'grayscale';
    % -- Disable Auto Exposure/Gain --
    if isprop(src,'ExposureAuto'), src.ExposureAuto = 'Off'; end
    if isprop(src,'GainAuto'),     src.GainAuto     = 'Off'; end
    % -- Disable Gamma, BlackLevel --
    if isprop(src,'GammaEnable'),  src.GammaEnable = false; end
    if isprop(src,'BlackLevel'),   src.BlackLevel  = 0;     end
    % -- Exposure Upper Limit --
    if isprop(src, 'AutoExposureUpperLimit')
        src.AutoExposureUpperLimit = 32000000; % 32s limit (µs)
    end
    % -- Set Exposure/Gain --
    if ~isempty(exp_us) && isprop(src,'ExposureTime')
        src.ExposureTime = exp_us;   % Units in µs
    end
    if ~isempty(gain) && isprop(src,'Gain')
        src.Gain = gain;
    end
    % -- Enable TriggerMode --
    src.TriggerMode = 'On';
    vid.Timeout     = 3;
    % -- Start acquisition engine (Waiting for trigger) --
    start(vid);
    disp('📷 Camera ready (software trigger).');
end