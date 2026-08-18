function led_off(s,cmdGap_s)
%LED_ON 点亮指定 LED
% s   : 串口对象 (serialport)
% RGB : 字符串, 三个字符表示 R/G/B 亮度，例如 '9az'
% ID  : LED 编号 (0–99)

    writeline(s, 'lcl00');
    pause(cmdGap_s);
end
