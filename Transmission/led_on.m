function led_on(s, RGB, ID,settle_s)
%LED_ON 点亮指定 LED
% s   : 串口对象 (serialport)
% RGB : 字符串, 三个字符表示 R/G/B 亮度，例如 '9az'
% ID  : LED 编号 (0–99)

   

    % 构造最终命令，例如: "lct 10 9az 21"
    cmd = sprintf('lct%s%s%s', '05', RGB, ID);

    writeline(s, cmd);
    if settle_s>0, pause(settle_s); end   % LED settle 1 ms
end
