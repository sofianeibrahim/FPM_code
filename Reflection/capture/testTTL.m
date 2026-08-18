% 1. Create video object (Adapted to your camera name)
vid = videoinput('gentl', 1, 'Mono8');  % Example: Using GenTL interface + Mono8 format
src = getselectedsource(vid);
vid.ROIPosition = [0 0 640 480]; 

% 2. Set external hardware trigger parameters
triggerconfig(vid, 'hardware', 'DeviceSpecific', 'DeviceSpecific'); 
src.TriggerSource = 'Line0';            % Corresponds to GPIO Pin 1 (Black wire)
src.TriggerMode = 'On';                 % Enable external triggering

% Set trigger to "Falling Edge" mode
src.TriggerActivation = 'FallingEdge';
vid.TriggerRepeat = 0;                   % Manual acquisition of one frame at a time
vid.FramesPerTrigger = 1;               % Capture 1 image per trigger
vid.Timeout = 10;                       % Set maximum wait time (seconds)

% 3. Start acquisition
start(vid);
fprintf('Waiting for TTL trigger signal...\n');

for i = 1:5
    fprintf("Waiting for trigger %d ...\n", i);
    
    % getsnapshot blocks execution until a TTL trigger is received or timeout occurs
    try
        img = getsnapshot(vid);           % Acquire image (only succeeds upon trigger)
        imshow(img, []);
        title(['Frame ' num2str(i)]);
        pause(0.5);
    catch ME
        warning("Wait for trigger %d timed out or failed: %s", i, ME.message);
    end
end

stop(vid);
fprintf('Test complete. Video acquisition stopped.\n');