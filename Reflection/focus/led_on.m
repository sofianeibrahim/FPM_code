function led_on(s, RGB, ID)
% LED_ON Turn on a specific LED via serial communication
%
% s   : serial port object (serialport)
% RGB : string specifying R/G/B intensity using three characters,
%       e.g. '9az' (one character per color channel)
% ID  : LED index (0–99)
%
% This function constructs and sends a serial command to the LED controller.
% Example command format:
%   "lct05<RGB><ID>"
% e.g. "lct059az21"
%
% The command is sent via the given serial port.

    % Construct final command string
    cmd = sprintf('lct%s%s%s', '05', RGB, ID);
    % Send command to LED controller
    writeline(s, cmd);
end
