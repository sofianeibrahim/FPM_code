%% MATLAB Script: Synchronized Arduino LED Control + CMOS Image Acquisition
% Requirements:
% - Arduino receives [r g b brightness timeHigh timeLow]
% - One color set is sent per round to light up 25 LEDs; Arduino triggers CMOS for each LED
% - MATLAB acquires and saves 25 images
%% Initialize Serial Port
s = init_serialport("COM5", 9600); % Replace with your actual port
%% Wait for Arduino to be ready
while true
    if s.NumBytesAvailable > 0
        msg = readline(s);
        if contains(msg, "READY")
            break;
        end
    end
end
disp("Arduino is ready.");

%% Initialize CMOS Camera
vid = videoinput('gentl', 1, 'Mono8');
src = getselectedsource(vid);
src.TriggerMode = 'On';
src.TriggerSource = 'Line0';
src.TriggerActivation = 'RisingEdge';
src.ExposureTime = 1000000; % 1 second
vid.FramesPerTrigger = 1;
vid.TriggerRepeat = Inf;
vid.Timeout = 5;

% Define save path
baseDir = 'images';
mkdir(baseDir);
start(vid);

%% LED Scan Parameters: RGB + Brightness + On-time per LED (ms)
scanParams = {
    [255, 0, 0], 30, 1000;   % Red
    [0, 255, 0], 30, 800;    % Green
    [0, 0, 255], 30, 1200;   % Blue
};


for round = 1:3
    rgb = uint8(scanParams{round, 1});
    brightness = uint8(scanParams{round, 2});
    duration = uint16(scanParams{round, 3});
    
    % Split 16-bit duration into high and low bytes
    highByte = bitshift(duration, -8);
    lowByte = bitand(duration, 255);
    
    % Create subdirectory for the current round
    subDir = fullfile(baseDir, sprintf('round%d', round));
    if ~exist(subDir, 'dir')
        mkdir(subDir);
    end
    
    % Send control packet to Arduino
    cmd = [rgb, brightness, highByte, lowByte];
    write(s, cmd, "uint8");
    
    % Acquire and save 25 images
    for led = 1:25
        % Wait for frame to arrive in buffer
        maxWait = 2;
        tic;
        while vid.FramesAvailable < 1
            if toc > maxWait
                error('Timeout: Image did not arrive.');
            end
            pause(0.005);
        end
        
        % Retrieve frame and save
        frame = getdata(vid, 1);
        fname = sprintf('led%02d.png', led);
        fpath = fullfile(subDir, fname);
        imwrite(frame, fpath);
        
        % Send "DONE" acknowledgment to Arduino
        writeline(s, 'DONE');
    end
    
    % Wait for Arduino to signal "DONE" for the complete round
    while true
        if s.NumBytesAvailable > 0
            msg = readline(s);
            if contains(msg, "DONE")
                break;
            end
        end
    end
end

stop(vid);
delete(vid);
clear vid;

%% Serial Port Initialization Function
function s = init_serialport(comPort, baudRate)
    delete(serialportfind);
    s = serialport(comPort, baudRate);
    configureTerminator(s, "LF");
    pause(0.5);
end