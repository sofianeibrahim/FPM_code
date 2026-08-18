function run_led_capture_sequence(vid, acqState)
    % Get scan parameters
    params = acqState.scanParams;
    numRounds = size(params, 1);
    
    for roundIdx = 1:numRounds
        % Update indices
        acqState.roundIdx = roundIdx;
        acqState.frameIdx = 0;
        
        % --------- 1. Send RGB Parameters for the Current Round ----------
        rgb = params{roundIdx, 1};             % Extract RGB vector from cell array
        brightness_BF = params{roundIdx, 2};   % Extract Brightfield brightness
        duration_BF = params{roundIdx, 3};
        brightness_DF = params{roundIdx, 4};   % Extract Darkfield brightness
        duration_DF = params{roundIdx, 5};     % Extract duration (Unit: ms)
        
        % Construct command packet (uint8)
        cmd = [ ...
            uint8(170), ...                                   % 0xAA as Frame Header
            uint8(mod(acqState.frameIdx, 256)), ...           % Frame ID/Number
            uint8(rgb), ...
            uint8(brightness_BF), ...
            typecast(uint16(duration_BF), 'uint8'), ...
            uint8(brightness_DF), ...
            typecast(uint16(duration_DF), 'uint8') ...
        ];
        
        % Set camera exposure time (us)
        duration = 2000; %in ms
        exposure_us = duration * 1000;
        src = getselectedsource(vid);
        
        % Attempt to set exposure time directly (in microseconds)
        try
            src.ExposureTime = exposure_us;
        catch
            warning("Current video source does not support direct ExposureTime setting.");
        end
        
        % Send serial command
        write(acqState.serialObj, cmd, 'uint8');
        fprintf("📤 Round %d LED CMD Sent: [%s]\n", roundIdx, num2str(cmd));
        
        % --------- 2. Wait for Arduino feedback to trigger capture ----------
        for frameIdx = 1:acqState.NUM_LEDS
            % Update status
            acqState.frameIdx = frameIdx;
    
            % Wait for Arduino to return "EXPOSURE_DONE"
            while true
                if acqState.serialObj.NumBytesAvailable > 0
                    msg = readline(acqState.serialObj);
                    msg = strtrim(string(msg));
    
                    if contains(upper(msg), "EXPOSURE_DONE")
                        % ✅ Proceed with image capture
                        fprintf("📷 Capturing image for frame %d\n", frameIdx);
                        frameCapturedCallback(vid, acqState);
                        flush(acqState.serialObj);  % Clear subsequent residual data
                        break;  % Exit loop to continue to next frame
                    else
                        warning("❌ Unexpected serial message received: %s", msg);
                        flush(acqState.serialObj);  % Prevent residual data buildup
                
                        % If Arduino sends RETRY, it means it didn't receive the previous confirmation
                        if contains(upper(msg), "RETRY")
                            fprintf('[MATLAB] ⚠️ Resending CAPTURE_DONE:%d\n', frameIdx);
                            fprintf(acqState.serialObj, "CAPTURE_DONE:%d\n", frameIdx);
                            flushoutput(acqState.serialObj);  % Clear output buffer
                        else
                            % Other abnormal cases
                            warning("⚠️ Ignoring unrecognized message.");
                        end
                    end
                end
    
                pause(0.001);  % Prevents high CPU usage (yield)
            end
        end
    end
end