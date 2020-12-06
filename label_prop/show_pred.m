% pred_dir = '/home/shared/work/NAS/label_prop/hotel_umd40/label_pred_backflow_and_geom/';
% rgb_dir = '/home/shared/work/NAS/label_prop/hotel_umd40/RGB/';
% pred_vis = '/home/shared/work/NAS/label_prop/hotel_umd40/label_pred_backflow_and_geom/vis/';

% pred_dir = '/home/shared/work/NAS/label_prop/hotel_umd40/label_pred_fwdflow_and_geom/';
% rgb_dir = '/home/shared/work/NAS/label_prop/hotel_umd40/RGB/';
% pred_vis = '/home/shared/work/NAS/label_prop/hotel_umd40/label_pred_fwdflow_and_geom/vis/';

% pred_dir = '/home/shared/work/NAS/label_prop/hotel_umd40/label_pred_geom_NO_SMOOTHING/';
% rgb_dir = '/home/shared/work/NAS/label_prop/hotel_umd40/RGB/';
% pred_vis = '/home/shared/work/NAS/label_prop/hotel_umd40/label_pred_geom_NO_SMOOTHING/vis/';

%video_name      = 'studyroom';
%video_name = 'hv_c6';
video_name = 'hotel_umd40';

src_dir         = '/media/New Volume/label_prop/';

pred_dir = [src_dir video_name '/label_pred_geom_only_13/'];
rgb_dir = [src_dir video_name '/RGB/'];
pred_vis = [src_dir video_name '/label_pred_geom_only_13/vis/'];


files = dir([pred_dir '*.mat']);
color = [0 0 0 ;%background
        0 0 255 ;%bed
        255 102 102 ;%#books
        0 0 20 ;%ceil
        0 102 204 ;%#books
        255 255 0 ; %floor
        0 204 204 ;%furn
        102 0 255 ;%#obj
        153 255 204 % painting
        102 0 0 ; % sofa
        255 0 255 ;%#table
        0 102 102 ;%#tv
        255 128 0 ;%wall
        192 192 192 ;%#window        
        ];
load([src_dir video_name '/keyframes.mat'], 'keyframes');
for iFiles=1:length(files)
    fileName = files(iFiles).name(1:end-4);
    load([pred_dir fileName '.mat']);
    rgbP         = imread([rgb_dir  'rgb_' fileName '.png']);
    
    %cropping parameters, crop images to ramove the boarder 
    x1 = 41; x2 = 600;
    y1 = 46; y2 = 470;       
    rgbP = rgbP(y1:y2,x1:x2,:);
    
    % labeled image
    predIds = unique(smoothedPredCp(:));
    predImg = zeros(size(smoothedPredCp,1)*size(smoothedPredCp,1),3);
    for iPredIds=1:length(predIds)
        idx = find(smoothedPredCp == predIds(iPredIds));
        predImg(idx,:) = repmat(color(predIds(iPredIds),:), length(idx),1);
    end
    predImg = reshape(predImg, [size(smoothedPredCp,1) size(smoothedPredCp,2) 3]);
    
    isKeyframe = '*';
    if (~isempty(find(keyframes == str2num(fileName))))        
        subplot(1,2,1); imagesc(rgbP); title([isKeyframe 'rgb-frame-' ]);
    else
        subplot(1,2,1); imagesc(rgbP); title(['rgb-frame-' fileName]);
    end
    subplot(1,2,2); imagesc(predImg); title(['propagated label-' fileName]);    
    
    if (~exist(pred_vis))
        mkdir(pred_vis);
    end
    img_ = im2frame(zbuffer_cdata(gcf));
    im_save_as = [pred_vis '/' fileName '.png'];
    imwrite(img_.cdata, [im_save_as]);    
%     keyboard;
    %figure; imagesc(superLabel); title(fileName);

    %pause(1);
    close;    
end