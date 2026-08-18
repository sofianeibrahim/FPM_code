% === init_serialport.m ===
% Usage: s = init_serialport("COM3", 9600);
function s = init_serialport(comPort, baudRate)
    % Clean up old serial port objects
    % Close and delete all existing serial port connections
    delete(serialportfind);
    
    % Establish a new serial port connection
    s = serialport(comPort, baudRate);
    
    % Set terminator to Line Feed (LF) for handshaking protocols
    configureTerminator(s, "LF");  
    
    % Pause briefly to allow serial port initialization to complete
    pause(0.5);  
end