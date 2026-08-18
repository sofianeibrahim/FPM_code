function pos81 = build_ring_order_9x9()
% 输出按 "77 -> 第一圈(从66开始顺时针) -> 第二圈 -> ... -> 第四圈"的 81 个ID
    cx = 7; cy = 7;                    % 中心 77
    pos81 = {'77'};                    % 先放中心
    for r = 1:4                        % 四圈：r=1..4 -> 8,16,24,32 个点
        xL = cx - r; xR = cx + r;
        yT = cy - r; yB = cy + r;

        % 顶边：y=yT，x: xL..xR （起点 66 对应 r=1 时 xL=6, yT=6）
        for x = xL:xR
            pos81{end+1} = sprintf('%s%s', hex1(yT), hex1(x)); %#ok<AGROW>
        end
        % 右边：x=xR，y: yT+1..yB
        for y = (yT+1):yB
            pos81{end+1} = sprintf('%s%s', hex1(y), hex1(xR)); %#ok<AGROW>
        end
        % 底边：y=yB，x: xR-1..xL （从右往左）
        for x = (xR-1):-1:xL
            pos81{end+1} = sprintf('%s%s', hex1(yB), hex1(x)); %#ok<AGROW>
        end
        % 左边：x=xL，y: yB-1..yT+1 （从下往上，避免重复拐角）
        for y = (yB-1):-1:(yT+1)
            pos81{end+1} = sprintf('%s%s', hex1(y), hex1(xL)); %#ok<AGROW>
        end
    end
end

function ch = hex1(n)
% 0..14 -> '0'..'e'（你的阵列是 0..e）
    if n<=9, ch = char('0'+n); else, ch = char('a'+(n-10)); end
end
