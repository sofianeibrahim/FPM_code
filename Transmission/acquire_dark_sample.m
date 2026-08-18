function dark = acquire_dark_sample(vid, src, N)
if nargin<3, N=4; end
% 清空残帧
n = vid.FramesAvailable; if n>0, getdata(vid,n); end
% 叠加平均
vr = get(vid,'VideoResolution'); W = vr(1); H = vr(2);
acc = zeros(H,W,'double');
for i=1:N
    acc = acc + double(snap_shot(vid, src));
end
dark = uint16(acc / N);
end

