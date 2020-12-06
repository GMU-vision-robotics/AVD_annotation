clear; clc;
% training
video_names = {'hotel_umd40', 'hv_c5', 'studyroom', 'mit_32'};
% testing    

% video_names = {'dorm', 'hv_c6', 'hv_c8', 'mit_lab'};

src_dir         = '/media/arsalan/019df09f-5268-4305-9045-26461d32ad57/label_props/';

color = [0 0 0 ;%background
        0 0 255 ;%bed
        %255 102 102 ;%books
        0 0 20 ;%ceil
        0 102 204 ;%chair
        255 255 0 ; %floor
        0 204 204 ;%furn
        102 0 255 ;%obj
        153 255 204 % painting
        %102 0 0 ; % sofa
        255 0 255 ;%table
        %0 102 102 ;%tv
        255 128 0 ;%wall
        192 192 192 ;%window        
        ];

  
newLabelMap = containers.Map;
% map container       % OLD LABEL      NEW LABEL
%================================================
newLabelMap('0') = 0; % bg      (0) -> bg    (0)
newLabelMap('1') = 1; % bed     (1) -> bed   (1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
newLabelMap('2') = 0; % books   (2) -> bg    (0)                    'book' should not exist, in case exist relabel them into 'background'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

newLabelMap('3') = 2; % ceil    (3) -> ceil  (2)
newLabelMap('4') = 3; % chair   (4) -> chair (3)
newLabelMap('5') = 4; % floor   (5) -> floor (4)
newLabelMap('6') = 5; % furn    (6) -> furn  (5)
newLabelMap('7') = 6; % objs    (7) -> objs  (6)
newLabelMap('8') = 7; % picture (8) -> pictur(7)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
newLabelMap('9') = 5; % sofa    (9) -> furn  (5)                    'sofa' relabel into 'furn'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

newLabelMap('10') = 8; % table  (10)-> table (8)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
newLabelMap('11') = 0; % tv     (11)-> bg    (0)                    'tv' should not exist, in case exist relabel them into 'background'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
newLabelMap('12') = 9; % wall   (12)-> wall  (9)
newLabelMap('13') = 10;% window(13)->window (10)
f1 = figure;
for iVideo=2:2%length(video_names)
    
    video_name = video_names{iVideo};
    
    newLabelDir = [src_dir video_name '/label10/'];
    
    if (~exist(newLabelDir, 'dir'))
        mkdir(newLabelDir);
        system(['chmod 777 ' newLabelDir]);
    end
    
%     clear keyframes;
%     load([video_name '/keyframes.mat'], 'keyframes');
    
    files = dir([src_dir video_name '/label/*.mat']);
    
    rgb_dir = [src_dir video_name '/RGB/'];
    
    for iFiles=1:length(files)
                
        fileName = files(iFiles).name;
        
        load([src_dir video_name '/label/' fileName], 'superLabel', 'mapLabel', 'mapLabel13', ...
                                                      'label', 'stat13', 'stat40');
                
        %rgbP    = imread([rgb_dir  'rgb_' fileName(1:end-4) '.png']);
        
        labels = unique(superLabel(:));    
        labels(find(labels==0)) = []; % delete zero
        
        mapLabel10 = zeros(size(mapLabel13));
        
        % it is a keyframe        
        if (~isempty(labels))
            % remap the mapLabel13 into a 10 class
            uniqueLabels = unique(mapLabel13(:));    
                        
            for iLabel=1:length(uniqueLabels)           
                curLabel = uniqueLabels(iLabel);
                idx = find(mapLabel13 == curLabel);
                newLabel = newLabelMap(num2str(curLabel));
                mapLabel10(idx) = newLabel;
                                
            end
        
        % it is a non-key frame hence there should be no information
        else
            % clear out the existing masystem(['chmod 777 ' newLabelDir])pLabel13 (Hui incorrectly copied back mapLabel13 from a previous frame)
            mapLabel13 = zeros(size(superLabel));
            
        end
        
        % save the information
        save([newLabelDir fileName], 'superLabel', 'mapLabel', 'mapLabel13', 'mapLabel10', ...
                                                   'label', 'stat13', 'stat40');
        system(['chmod 777 ' fileName]);
        
        if (0)
            figure(f1);
            subplot(2,2,1); imagesc(mapLabel10); title(['mapLabel10 - ' fileName(1:end-4)]);
            subplot(2,2,2); imagesc(superLabel); title(['superlabel - ' fileName(1:end-4)]); 
            subplot(2,2,3); imagesc(mapLabel); title(['mapLabel - ' fileName(1:end-4)]);
            subplot(2,2,4); imagesc(mapLabel13); title(['mapLabel13 - ' fileName(1:end-4)]);            
            pause; clf;                 
        end
        clear superLabel mapLabel mapLabel13 mapLabel10;
        display([num2str(iFiles) '. finished processing ' video_name ': ' fileName]);
        %pause(0.3);
    end
    %save([video_name '/allKeyframes.mat'], 'keyframes');    

end

% per_video_class_dist = zeros(length(video_names),14);
% video_class_dist = zeros(1, 14);
% 
% for iVideo=1:length(video_names)
% 
%     video_name = video_names{iVideo};
%     
%     gt_dir = [src_dir video_name '/label/'];
%     rgb_dir = [src_dir video_name '/RGB/'];
% 
%     %files = dir([gt_dir '*.mat']);
%     load([src_dir video_name '/keyframes.mat'], 'keyframes');
% 
%     for iFiles=1:length(keyframes)
%         n = keyframes(iFiles);
%         strName = sprintf('%04d',n);
%         
%         load([gt_dir strName '.mat']);
%         
%         classes = unique(mapLabel13(:))' + 1;
%         per_video_class_dist(iVideo,classes) = per_video_class_dist(iVideo, classes) + 1; 
%         
%         
%         rgbP         = imread([rgb_dir  'rgb_' strName '.png']);
% % % % 
% % % %         %cropping parameters, crop images to ramove the boarder 
% % % %         x1 = 41; x2 = 600;
% % % %         y1 = 46; y2 = 470;       
% % % %         rgbP = rgbP(y1:y2,x1:x2,:);
% 
% 
% 
%     % % %     % labeled image
%     % % %     predIds = unique(smoothedPredCp(:));
%     % % %     predImg = zeros(size(smoothedPredCp,1)*size(smoothedPredCp,1),3);
%     % % %     for iPredIds=1:length(predIds)
%     % % %         idx = find(smoothedPredCp == predIds(iPredIds));
%     % % %         predImg(idx,:) = repmat(color(predIds(iPredIds),:), length(idx),1);
%     % % %     end
%     % % %     predImg = reshape(predImg, [size(smoothedPredCp,1) size(smoothedPredCp,2) 3]);
%     % % %     
%     % % %     isKeyframe = '*';
%     % % %     if (~isempty(find(keyframes == str2num(fileName))))        
%     % % %         subplot(1,2,1); imagesc(rgbP); title([isKeyframe 'rgb-frame-' ]);
%     % % %     else
%     % % %         subplot(1,2,1); imagesc(rgbP); title(['rgb-frame-' fileName]);
%     % % %     end
%     % % %     subplot(1,2,2); imagesc(predImg); title(['propagated label-' fileName]);    
%     % % %     
%     % % %     if (~exist(pred_vis))
%     % % %         mkdir(pred_vis);
%     % % %     end
%     % % %     img_ = im2frame(zbuffer_cdata(gcf));
%     % % %     im_save_as = [pred_vis '/' fileName '.png'];
%     % % %     imwrite(img_.cdata, [im_save_as]);    
%     %     keyboard;
%         %figure; imagesc(superLabel); title(fileName);
% 
%         %pause(1);
% % % %         close;    
%     end
%     video_class_dist = video_class_dist + per_video_class_dist(iVideo,:);
% end