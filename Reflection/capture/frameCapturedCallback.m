function frameCapturedCallback(vid, acqState)
    % Acquire image (with 1s timeout)
    frame = getdata(vid, 1, 'uint16');       % Retrieve one frame in uint16 format
    
    % Create subdirectory for the current round
    subDir = fullfile(acqState.baseDir, sprintf('round%d', acqState.roundIdx));
    if ~exist(subDir, 'dir')
        mkdir(subDir);
    end
    
    % Construct filename
    fname = sprintf('led%02d.tiff', acqState.frameIdx);
    fpath = fullfile(subDir, fname);
    
    % Save image
    imwrite(frame, fpath);
    fprintf('[Callback] Image saved: %s\n', fpath);
    
    % Send image capture completion signal to Arduino
    msg = sprintf("CAPTURE_DONE:%d\n", acqState.frameIdx);
    
    % Clear output buffer
    flushoutput(acqState.serialObj);  
    
    % Send message explicitly as a string format
    fprintf(acqState.serialObj, '%s', msg);  
    
    % Brief pause to ensure data integrity and prevent serial loss
    pause(0.01);  
end