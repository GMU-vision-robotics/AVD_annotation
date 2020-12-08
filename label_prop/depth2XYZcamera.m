function XYZcamera = depth2XYZcamera(K, depth, DEPTH_CUTOFF_THRESHOLD)
    [r, c] = size(depth);
    [x,y] = meshgrid(1:c, 1:r);
    
    % negate the x-coordinate to conform to colmap
    %XYZcamera(:,:,1) = -(x-K(1,3)).*depth/K(1,1);
    %------------------------------------------------
    
    XYZcamera(:,:,1) = (x-K(1,3)).*depth/K(1,1);
    XYZcamera(:,:,2) = (y-K(2,3)).*depth/K(2,2);
    XYZcamera(:,:,3) = depth;
    if (~exist('DEPTH_CUTOFF_THRESHOLD', 'var'))
        XYZcamera(:,:,4) = depth~=0;    
    else
        valid =  (depth~=0) & (depth < DEPTH_CUTOFF_THRESHOLD);
        XYZcamera(:,:,4) = valid;
    end
    
end
