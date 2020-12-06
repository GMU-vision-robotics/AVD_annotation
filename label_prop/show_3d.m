

pred_dir = '/home/shared/work/NAS/label_prop/hotel_umd40/label_pred_backflow_only/';
rgb_dir = '/home/shared/work/NAS/label_prop/hotel_umd40/RGB/';
pred_vis = '/home/shared/work/NAS/label_prop/hotel_umd40/label_pred/vis/';
worldpc_dir = '/home/shared/work/NAS/label_prop/hotel_umd40/worldpc/';
files = dir([pred_dir '*.mat']);
color = [0 0 0;
        0 255 255;
        255 0 0;
        0 255 0;
        0 0 255];
    x1 = 41; x2 = 600;
    y1 = 46; y2 = 470;       
    
load('umd_hotel_keyframes.mat', 'keyframes');
load('hotel_umd40/intrinsic_hotel_umd.mat');
load('hotel_umd40/extrinsic.mat'); % extrinsics from camera 2 world coordinates

f1 = figure;
XYZworldAll = [];
XYZlabelAll = [];
for iFiles=19:65%length(files)
    fileName = files(iFiles).name(1:end-4);
    load([pred_dir fileName '.mat']);
    

    rgbP         = imread([rgb_dir  'rgb_' fileName '.png']);
    RGB          = reshape(rgbP,[],3)';

    
    % FIND THE VALID CROPPED INDICES
    valid = zeros(size(rgbP,1), size(rgbP,2));
    valid(y1:y2,x1:x2) = 1;
    validIndex = find(valid == 1);
    
    % for 5 category pixels  
    SLabel = zeros(3, length(validIndex));
    for iLabel=1:5
        idx = find(smoothedPredCp == iLabel)';
        if (~isempty(idx))
            SLabel(:,idx) = repmat(color(iLabel,:)', 1, length(idx));
        end
    end        
        
    
    RGB = RGB(:,validIndex);
        
    load([worldpc_dir 'rgb_'  fileName '.mat']);
    XYZworld = XYZworld(:,validIndex);   
    XYZworldAll = cat(2, XYZworldAll, XYZworld);
    
    % transfer the label from the the image space
    XYZlabelAll = cat(2, XYZlabelAll, smoothedPredCp(:)');
    
    extrinsicIndex = str2num(fileName);
    Rc2w = extrinsicsC2W(1:3,1:3, extrinsicIndex);
    Tc2w = extrinsicsC2W(1:3,4, extrinsicIndex);
    pts = bsxfun(@minus, Rc2w'*Tc2w, Rc2w'*XYZworldAll); % x=(Rc2w')*X-(Rc2w')*(Tc2w)

%     pts = pts(:,tmpIndex);
    pts = pts';
        
    
    % project the labels back to the frame
    focal_length_x = K(1,1);
    focal_length_y = K(2,2);
    center = [K(1,3) K(2,3)];
    croppedRGB = rgbP(y1:y2, x1:x2, :);
    %figure; imagesc(rgbP);
    projX=[]; projY=[];   
    projIndices = [];    
    for j=1:size(pts,1)
        projX(j)=round((pts(j,1)*focal_length_x)/pts(j,3) + center(1)) - (x1-1);
        projY(j)=round((pts(j,2)*focal_length_y)/pts(j,3) + center(2)) - (y1-1);        
%         if ((projX(j) > 0 && projX(j) <= size(smoothedPredCp,2)) && ...
%             (projY(j) > 0 && projY(j) <= size(smoothedPredCp,1)))
%             projIndices = cat(1, projIndices, j);
%         end
    end    
    
    tmpIndex = find((projX > 0 & projX <= size(smoothedPredCp,2)) & (projY > 0 & projY <= size(smoothedPredCp,1)));
    projIndices = cat(2, projIndices, tmpIndex');
    
    projX = projX(projIndices);
    projY = projY(projIndices);    
    projL = XYZlabelAll(projIndices);
    
    f1 = figure; imagesc(croppedRGB); title('projected from global point cloud');
    position1 = get(f1, 'OuterPosition');
    set(f1, 'OuterPosition', [10 position1(2:4)]);
    hold on;
    tmpIndex = find(projL == 5);
    plot(projX(tmpIndex), projY(tmpIndex), '.g');        
    %keyboard;
    
    f2 = figure; imagesc(croppedRGB); title('predicted from previous frame');
    position2 = get(f2, 'OuterPosition');
    set(f2, 'OuterPosition', [position1(3)+230 position2(2:4)]);
    hold on;
    [yy_, xx_] = find(smoothedPredCp == 5);
    plot(xx_, yy_, '.g');
    %keyboard;
    
%     hold on;
%     %f1 = visualizePointCloud(XYZworld,RGB,[], 0, 10, f1);  
%     f1 = visualizePointCloud(XYZworld, SLabel,[], 0, 10, f1);  
%     view(160, -50);
    clear smoothedPredCp XYZworld RGB;
    pause(3);
    close all;
    
end