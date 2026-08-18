function vid = init_camera()
% Initialize camera, set to Line0 Falling Edge trigger
    imaqreset;  % Reset image acquisition hardware
    vid = videoinput('gentl', 1, 'Mono16');  % Select GenTL adapter, Device ID 1, Format Mono16
    src = getselectedsource(vid);  % Get the source object
    
    % Set hardware trigger mode
    triggerconfig(vid, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
    
    % Set trigger source to Line0 (External TTL input)
    src.TriggerSource = 'Line0';
    
    % Set trigger activation to "Falling Edge" mode
    src.TriggerActivation = 'FallingEdge';
    
    % Set to continuous acquisition mode (Commented out in original)
    %src.AcquisitionMode = 'Continuous';
    
    % Set maximum exposure time (microseconds), limited to 100,000 us
    if isprop(src, 'ExposureTime')
        src.ExposureTime = min(src.ExposureTime, 40); %µs
    end
    
    % Capture exactly one frame per trigger
    vid.FramesPerTrigger = 1;
    vid.TriggerRepeat = Inf;  % Allow infinite triggers
    
    % Set the returned image to grayscale
    vid.ReturnedColorspace = 'grayscale';
    
    % Essential step: Enable Trigger Mode
    if isprop(src, 'TriggerMode')
        src.TriggerMode = 'On';
    end
    
    % Start the camera acquisition engine
    start(vid);
    fprintf('✅ Camera initialization complete: Set to Line0 Falling Edge trigger.\n');
end