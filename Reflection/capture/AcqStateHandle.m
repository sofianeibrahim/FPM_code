classdef AcqStateHandle < handle
    properties
        baseDir
        serialObj
        roundIdx = 0;
        frameIdx = 0;
        NUM_LEDS = 41
        % Use a cell array to define scanning parameters (more versatile)
        scanParams = { ...
            [255, 255, 255],  50, 20, 100, 20;  % White (BF/DF) %s?
            % [R, G, B], Brightness_BF, Duration_BF, Brightness_DF, Duration_DF
            
        };
    end
    methods
        function obj = AcqStateHandle()
            % Generate a timestamp for the session folder
            timestamp = sprintf('%s', datetime("now", 'Format','yyyyMMdd_HHmmss'));
            % Set the base directory to 'capture_YYYYMMDD_HHMMSS' in the current path
            obj.baseDir = fullfile(pwd, ['capture_', timestamp]);
            % Create the directory if it does not already exist
            if ~exist(obj.baseDir, 'dir')
                mkdir(obj.baseDir);
            end
        end  
    end
end