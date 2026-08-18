function focus_mode()
    % 建立相机对象
    if exist('vid', 'var') && isvalid(vid)
        stop(vid);          % 停止采集
        delete(vid);        % 删除对象
    end
imaqreset; 
    vid = videoinput('gentl', 1, 'Mono16');  
    src = getselectedsource(vid);
    src.TriggerMode = 'Off';   % 聚焦阶段用自由采集
    start(vid);

    figure; 
    while ishandle(gcf)
        img = getsnapshot(vid);  
        img = double(img);

        % 清晰度：Laplacian方差
        h = fspecial('laplacian',0.2);
        lap = imfilter(img,h,'replicate');
        sharpness = var(lap(:));

        imshow(img,[]); 
        title(sprintf('Focus metric = %.2f', sharpness));
        drawnow;
    end

    stop(vid);
    delete(vid);
end
