

close all
clc


% project World frame to camera frame
% % % 
% % % % choose the scene and the frame
% % % sc = 13;
% % % fr = 222;
% % % 
% % % if sc<10, scene_path = ['rgbd-scenes-v2/imgs/scene_0', num2str(sc)]; scene_num = ['0',num2str(sc)]; 
% % % else scene_path = ['rgbd-scenes-v2/imgs/scene_', num2str(sc)]; scene_num = num2str(sc);  end
% % % numOfFrames = length(dir(scene_path))/2 - 4;
% % % 
% % % % load all the scene info
% % % scene_info_path = ['rgbd-scenes-v2_info/pc/', scene_num];
% % % labels = load([scene_info_path, '.label']);
% % % poses = load([scene_info_path, '.pose']);
% % % if ~exist(['scene_pts_',scene_num,'.mat'], 'file'), 
% % %     scene_pts = readPly([scene_info_path, '.ply']); % world coordinate points
% % %     save(['scene_pts_',scene_num,'.mat'], 'scene_pts');
% % % else
% % %     load(['scene_pts_',scene_num,'.mat']); % loads world coordinate points
% % % end
% % % 
% % % if fr<10, file = [scene_path, '/0000', num2str(fr)];
% % % elseif fr<100, file = [scene_path, '/000', num2str(fr)]; 
% % % else file = [scene_path, '/00', num2str(fr)]; 
% % % end
% % % 
% % % 
% % % img = imread([file, '-color.png']);
% % % 
% % % if ~exist([file, '_filledDepth.mat'], 'file')
% % %     depth = imread([file, '-depth.png']); depth = double(depth);
% % %     depth = fill_depth_colorization(double(img)/255, depth/1e4); %1e3 previously %From the NYU-V2 toolbox 
% % %     depth = round(depth*1e3);
% % %     save([file, '_filledDepth.mat'], 'depth');
% % % else
% % %     load([file, '_filledDepth.mat']);
% % % end
% % % 
% % % 
% % % %depth = depth/10; % for some reason the values of depth where scaled by 10
% % % labels = labels(2:length(labels));
% % % 
% % % figure; imagesc(img);
% % % figure; imagesc(depth); colormap gray;
% % % 
% % % quart = poses(fr,1:4);
% % % T = poses(fr,5:7);
% % % %pts = bsxfun(@plus,poses(fr,5:7),quatrotate([poses(fr,1) -poses(fr,2:4)],pts));
% % % %pts = bsxfun(@plus,T,quatrotate([quart(1) -quart(2:4)],scene_pts));

% convert quartenions to Rmatrix, Transform world coords to camera coords 
R=quaternion2matrix(quart);
pts = bsxfun(@minus, R'*T', R'*scene_pts')'; % x=R'X-R'T

% project the labels back to the frame
focal_length = 570.3;
center = [320 240];

x1=[]; y1=[];
for j=1:size(pts,1)
    x1(j)=round((pts(j,1)*focal_length)/pts(j,3) + center(1));
    y1(j)=round((pts(j,2)*focal_length)/pts(j,3) + center(2));
end

% check about overlapping coordinates
% % points = [x1;y1];
% % a=find(points(1,:)==291 & points(2,:)==222);
% % labels(a);

% label at position label(i) mapped to coords [y1(i),x1(i)]
label_map = zeros(size(depth,1), size(depth,2));                                
for i=1:length(x1)
    if isnan(y1(i)) || isnan(x1(i)) || y1(i) > 480 || y1(i) < 1 || x1(i) > 640 || x1(i) < 1, continue; end;
    % each point in the image frame can correspond to several in the camera
    % frame with different labels. Give priority to the objects labels
    % the labels are: (bowl=1, cap=2, cereal_box=3, coffee_mug=4, coffee_table=5,  
    % office_chair=6, soda_can=7, sofa=8, table=9, background=10)
    if label_map(y1(i),x1(i))==0 || label_map(y1(i),x1(i))==5 || label_map(y1(i),x1(i))==6 ...
         || label_map(y1(i),x1(i))==8 || label_map(y1(i),x1(i))==9 || label_map(y1(i),x1(i))==10 
        label_map(y1(i),x1(i)) = labels(i); % if empty, or non-object, label it
    else continue; 
    end;
end


% create the ground truth for each frame
frame_seg = zeros(size(label_map,1), size(label_map,2));
obj_count = 0;
class_list = {'bowl', 'cap', 'cereal_box', 'coffee_mug', 'coffee_table', 'office_chair', 'soda_can'};%, 'sofa', 'table', 'background'};
for i=1:length(class_list)
    if i==5 || i==6, continue; end;
    c = class_list{i};
    ids = find(label_map==i);
    mask = zeros(size(label_map,1), size(label_map,2));
    mask(ids) = i; % get the labelled object
    if ~sum(mask(:)), continue, end; 
    %figure; imagesc(mask);
    se=strel('square',5);
    mask2 = imclose(mask,se);
    
    % get connected components, this is needed to avoid small pixel groups,
    % and cover the situations where you have two instances of same class
    cc = bwconncomp(mask2);
    for k=1:cc.NumObjects 
        if length(cc.PixelIdxList{k}) < 100, continue; end;
        
        pixIds = cc.PixelIdxList{k};
        mask2 = zeros(size(label_map,1), size(label_map,2));
        mask2(pixIds) = i;
        %figure; imagesc(mask2);

        % for overlapping cases keep the label that was found first
        % this choice should be taken based on the depth of each point
        x=zeros(size(find(mask2>0))); y=zeros(size(find(mask2>0))); g=0;
        for w=1:size(mask2,1) % 480
            for h=1:size(mask2,2) % 640
                if mask2(w,h) > 0
                    g=g+1;
                    x(g) = w;
                    y(g) = h;
                    if frame_seg(w,h) > 0, continue; end;
                    frame_seg(w,h) = mask2(w,h);
                end
            end
        end
        
        obj_count=obj_count+1; 
        %bboxes = addBB(bboxes, 1, obj_count, c, i, min(x), max(x), min(y), max(y));
        bboxes{fr}(obj_count).category = c; % 1 should be replaced with frameNo
        bboxes{fr}(obj_count).label = i;
        bboxes{fr}(obj_count).top = min(x);
        bboxes{fr}(obj_count).bottom = max(x);
        bboxes{fr}(obj_count).left = min(y);
        bboxes{fr}(obj_count).right = max(y);
         
    end
end

f0=figure; imagesc(label_map);

frame_seg(find(frame_seg==0)) = 10;        
f1=figure; imagesc(frame_seg);

f2=figure; imagesc(img); hold on;
for i=1:size(bboxes{fr},2)
    info = bboxes{fr}(i);
    vis_bb = [info.left info.top info.right-info.left info.bottom-info.top];
    rectangle('position', vis_bb, 'EdgeColor', 'g', 'linewidth', 2);
end

% save the labels segmentation and bounding boxes vis
savepath = ['rgbd-scenes-v2/annotation/', 'scene_', scene_num];
if ~exist(savepath, 'dir'), mkdir(savepath); end;
saveas(f0, [savepath, '/', num2str(fr),'-labels.png']);
saveas(f1, [savepath, '/', num2str(fr),'-segm.png']);
saveas(f2, [savepath, '/', num2str(fr),'-bb.png']);
save([savepath, '/', num2str(fr),'-segm.mat'], 'frame_seg');
save([savepath, '/', num2str(fr),'-labels.mat'], 'label_map');
