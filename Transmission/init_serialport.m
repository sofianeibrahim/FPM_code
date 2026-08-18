% === init_serialport.m ===
% 用法：s = init_serialport("COM3", 9600);

function s = init_serialport(comPort, baudRate)
    % 清理旧串口对象
    % 关闭并删除所有串口连接
    delete(serialportfind);
    % 建立新的串口连接
    s = serialport(comPort, baudRate);
    configureTerminator(s, "LF");  % 设置换行符为 LF，用于 handshake
    pause(0.5);  % 稍等串口初始化
end