%function [] = debug_projection(XYZcamera, K, tmpLabelP)    
% whole 3D pcl of a frame projected into other
    pts = XYZcamera;
    focal_length_x = K(1,1);
    focal_length_y = K(2,2);
    center      = [K(1,3) K(2,3)];
    projX       = [];
    projY       = [];   
    projIndices = [];    
    
    %%%
    isClippingBehindCamera = 1;
    if (isClippingBehindCamera)
        frontOfCameraIndex  = find(pts(:,3) < 0);
        pts                 = pts(frontOfCameraIndex,:);
        tmpLabelP           = tmpLabelP(frontOfCameraIndex);                    
    end
    
    %%%
    % clipping on the image coordinate space
    for jj=1:size(pts,1)
        projX(jj)=round((pts(jj,1)*focal_length_x)/pts(jj,3) + center(1)) - (x1-1);
        projY(jj)=round((pts(jj,2)*focal_length_y)/pts(jj,3) + center(2)) - (y1-1);        
    end
    
    tmpIndex = find((projX > 0 & projX <= x2) & (projY > 0 & projY <= y2)); % CHANGE THE size(labelP,*) later on with parameter value
    % prune out elements that are not visible    
    pts         = pts(tmpIndex,:);    
    tmpLabelP   = tmpLabelP(tmpIndex);
    projX       = projX(tmpIndex);
    projY       = projY(tmpIndex);
    

    vis = 0;
    if (vis)
        rgbLabel = imread(fullfile(img_dir, [kfList{ikfList}, rgbExtension, rgbFileType]));           
        figure; imagesc(rgbC); title('current frame');
        figure; imagesc(rgbC); title('labeled pcl of a keyframe projected'); hold on; plot(projX, projY, '+g');
        figure; imagesc(rgbLabel); title('the keyframe')
        pause; %close(f3);
        %close all;
        %pts = XYZcamera;plot3(pts(1:500:end,1), pts(1:500:end,2), pts(1:500:end,3), '+g')
    end
    
    
    %%%    
    % occlusion reasoning
    regOI = zeros(r, c);
    projIndex = sub2ind([r, c], projY, projX);
    regOI(projIndex) = 1;
        
%     % depth of key-frame
%     tmpFileName = fullfile(depth_dir, [kfList{ikfList}, depthExtension, depthFileType]);        
%     depthKf = imread(tmpFileName);  
%     depthKf = depthKf/1000;
%     depthKf = depthKf(valid); % valid index were saved along with xyzworld 
%     depthKf = depthKf(tmpIndex);
    
    % depth of the current-frame
    tmpFileName = fullfile(depth_dir, [fileNameC, depthExtension, depthFileType]);        
    depth = double(imread(tmpFileName));  
    depth = depth/1000;
    DEPTH_CUTOFF_THRESHOLD = 7; % there are some artifacts in the depth image (active vision dataset). 7m or more
    valid =  (depth >= DEPTH_CUTOFF_THRESHOLD);
    depth(valid) = 0;
    
%     tmpFileName = fullfile(worldpc_dir, [fileNameC, worldpclExtension, worldpclFileType]);        
%     load(tmpFileName, 'valid');  % valid index is used to pick only those label-pixels that have valid XYZworld coordinate  
%     depth = depth(valid);
%     depth = depthKf(valid); % valid index were saved along with xyzworld 
%     depth = depthKf(tmpIndex);

    projDepth   = zeros(r,c);
    ptsDepth    = -pts(:,3);
    for jj=1:length(ptsDepth)
        
        curProjX = projX(jj);
        curProjY = projY(jj);
        
        % save the closest depth
        if (projDepth(curProjY, curProjX) == 0)
            projDepth(curProjY, curProjX) = ptsDepth(jj); % depths are negative in matlab coordinate system so convert them back to positive
        else
            projDepth(curProjY, curProjX) = min(projDepth(curProjY, curProjX), ptsDepth(jj));
        end
        
        
    end
    
    %figure; imagesc(projDepth); title('keyframe projected on curr only closest to camera projected');  
    depth(regOI ~= 1) = 0;
    
    % prune based on occluded part 
    %VISIBLE DEPTH IN CURRENT FRAME IS SMALLER THAN THE PROJECTED DEPTH
    
    DEPTH_DIFF_THRESHOLD = 0.1;
    % do the occlusion reasoning only on the visible depth part, the other
    % part take evidence from the projection (otherwise those will be empty)
    idx = find(depth == 0);
    tmp = projDepth;
    tmp(idx) = 0;
    
    % find the non-visible part where depth mask has zero values (missing from kinect after rgb2depth alignment)
    nonVisibleDepthMask = projDepth ~= 0;
    idx = find(tmp ~= 0);
    nonVisibleDepthMask(idx) = 0;
    
    
    % distance of occluded-reg will be larger than the occluding-reg    
    diff = tmp - depth; 
    idx = find(diff > DEPTH_DIFF_THRESHOLD);
%     figure; imagesc(tmp); title('projected depth from keyframe');
%     figure; imagesc(depth); title('depth from current frame');
%     figure; imagesc(diff); title('occluded part PrDepth > CurDepth');
    tmp(idx) = 0; % figure; imagesc(tmp); title('occluded part removed');
    
    % exclude the occluded part and add the region where depth value is missing
    idx = find(tmp ~= 0);
    projMaskWithoutOcclusion = zeros(r,c);
    projMaskWithoutOcclusion(idx) = 1;
    projMaskWithoutOcclusion(find(nonVisibleDepthMask == 1)) = 1;
    
    
    
    % delete the 3D points that are not within the valid projected part
%     updatedPts = [];
%     %updatedIndex = [];
%     updatedLabelP = [];
%     updatedProjX = [];
%     updatedProjY = [];
%     for jj=1:length(pts)
%         
%         curProjX = projX(jj);
%         curProjY = projY(jj);
%         curIndex = sub2ind([r,c], curProjY, curProjX);
%         if (mod(jj,100000))
%             display([num2str(jj) '/' num2str(length(pts))]);
%         end
%         % if the 3D point projects into valid region then save it
%         if (projMaskWithoutOcclusion(curProjY, curProjX))
%             
%             updatedProjX = cat(2, updatedProjX, curProjX);
%             updatedProjY = cat(2, updatedProjY, curProjY);
%             updatedPts = cat(1, updatedPts, pts(jj,:));
%             %updatedIndex = cat(2, updatedIndex, curIndex);
%             updatedLabelP = cat(2, updatedLabelP, tmpLabelP(jj));
%         end        
%         
%     end

   

    updatedIndex = sub2ind([r,c], projY, projX);
    projMaskWithoutOcclusionValues = projMaskWithoutOcclusion(updatedIndex);
    index = find(projMaskWithoutOcclusionValues == 1);
    
    projX       = projX(index);
    projY       = projY(index);
    pts         = pts(index,:);
    tmpLabelP   = tmpLabelP(index);
    XYZCamera   = pts;
    

    vis = 0;
    if (vis)
        
        figure; imagesc(depth); title('valid depth on the projected part');    
        figure; imagesc(projMaskWithoutOcclusion); title('proj with occluded part removed  within valid depth');
        rgbLabel = imread(fullfile(img_dir, [kfList{ikfList}, rgbExtension, rgbFileType]));           
        figure; imagesc(rgbC); title('current frame');
        figure; imagesc(rgbC); title('labeled pcl of a keyframe projected'); hold on; plot(projX, projY, '+g');
        figure; projectedLabel = zeros(r,c); tmpIndex = sub2ind([r,c], projY, projX); projectedLabel(tmpIndex) = tmpLabelP; imagesc(projectedLabel); title('labeled projected');
        figure; imagesc(rgbLabel); title('the keyframe')
        pause; %close(f3);
        close all;
        %pts = XYZcamera;plot3(pts(1:500:end,1), pts(1:500:end,2), pts(1:500:end,3), '+g')
    end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
   