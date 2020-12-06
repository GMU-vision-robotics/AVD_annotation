% select the foreground area for modeling the foreground distribution
dir_name = dir(['images']);
for ii=3:length(dir_name)
    im = imread(['./images/' dir_name(ii).name]);
    imshow(im);
    [x y] = ginput(2);
    data_pts = im(y(1):y(2), x(1):x(2),:);
    imshow(data_pts);
    pause; 

end