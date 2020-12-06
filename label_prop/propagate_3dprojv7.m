function propagate_3dprojv7(start, finish)
% This script is for the label propagation % It does the visibility 
% reasoning. As for occlusion reasoning, it accumulates the 3D labeled point 
% cloud from a window of W annotated frames around the frame under consideration. 
% Can't resolve error from occluded objects.

% Reza: 02/07/2018


close all;

%**************************************************************************
% video_name      = 'hotel_umd40';
% video_name      = 'studyroom';
% video_name      = 'hv_c6';
% video_name      = 'mit_32';
if (~exist('video_name', 'var'))
    %video_name        = 'Home_001_1';
    %video_name        = 'Home_005_1';
    %video_name        = 'Home_002_1';
    video_name        = 'Home_003_1';
end

rgbExtension         = '01';
depthExtension       = '03';
superpixelExtension  = '03';
labelExtension       = '01';
worldpclExtension    = '01';

rgbFileType          = '.jpg';
depthFileType        = '.png';
superpixelFileType   = '.mat';
labelFileType        = '.mat';
worldpclFileType     = '.mat';


% %cropping parameters, crop images to ramove the boarder (NYU-V2 and SUN3D)
% x1 = 41; x2 = 600;
% y1 = 46; y2 = 470;

% cropping parameters, crop images to ramove the boarder (active vision dataset)
% can't crop right now because 'worldpc' are saved without the crop hence
% there would index mismatch (REZA: 01-25-2018)
x1 = 1; x2 = 1920;
y1 = 1; y2 = 1080;

HAS_OBJECT_WEIGHT = 1;
IS_SLIDING_WINDOW = 0;

importantObjectNames = {'aunt_jemima_original_syrup', 'bumblebee_albacore', 'paper_plate', 'chair'};
%importantObjectIds = [2,3,32,47];
importantObjectIds = [2,3,32];
objectNameToNumberMap = containers.Map;
objectNameToNumberMap('aunt_jemima_original_syrup')                 = '2';
objectNameToNumberMap('bumblebee_albacore')                         = '3';
% objectNameToNumberMap('coca_cola_glass_bottle')                     = 5;
% objectNameToNumberMap('crystal_hot_sauce')                          = 7;
% objectNameToNumberMap('honey_bunches_of_oats_honey_roasted')        = 10;
% objectNameToNumberMap('honey_bunches_of_oats_with_almonds')         = 11;
% objectNameToNumberMap('hunts_sauce')                                = 12;
% objectNameToNumberMap('mahatma_rice')                               = 14;
% objectNameToNumberMap('nature_valley_granola_thins_dark_chocolate') = 15;
% objectNameToNumberMap('nutrigrain_harvest_blueberry_bliss')         = 16;
% objectNameToNumberMap('spongebob_squarepants_fruit_snaks')          = 17;
% objectNameToNumberMap('quaker_chewy_low_fat_chocolate_chunk')       = 20;
% objectNameToNumberMap('progresso_new_england_clam_chowder')         = 19;
% objectNameToNumberMap('softsoap_white')                             = 24;
% objectNameToNumberMap('spongebob_squarepants_fruit_snaks')          = 25;
% objectNameToNumberMap('nature_valley_sweet_and_salt_almond')        = 28;
objectNameToNumberMap('paper_plate')                                = '32';
% objectNameToNumberMap('pillow')                                     = 40;
% objectNameToNumberMap('sink')                                       = 44;
% objectNameToNumberMap('dining-table')                               = 46;
%objectNameToNumberMap('chair')                                      = 47;
% objectNameToNumberMap('remote')                                     = 49;
% 
% % weight for the small category
% 
objectNameToWeightMap = containers.Map;
objectNameToWeightMap(objectNameToNumberMap('aunt_jemima_original_syrup'))                 = 2.5;
objectNameToWeightMap(objectNameToNumberMap('bumblebee_albacore'))                         = 5.0;
% objectNameToWeightMap('coca_cola_glass_bottle')                     = 0.75;
% objectNameToWeightMap('crystal_hot_sauce')                          = 0.75;
% objectNameToWeightMap('honey_bunches_of_oats_honey_roasted')        = 0.75;
% objectNameToWeightMap('honey_bunches_of_oats_with_almonds')         = 0.75;
% objectNameToWeightMap('hunts_sauce')                                = 0.75;
% objectNameToWeightMap('mahatma_rice')                               = 0.75;
% objectNameToWeightMap('nature_valley_granola_thins_dark_chocolate') = 0.75;
% objectNameToWeightMap('nutrigrain_harvest_blueberry_bliss')         = 0.75;
% objectNameToWeightMap('spongebob_squarepants_fruit_snaks')          = 0.75;
% objectNameToWeightMap('quaker_chewy_low_fat_chocolate_chunk')       = 0.75;
% objectNameToWeightMap('progresso_new_england_clam_chowder')         = 0.75;
% objectNameToWeightMap('softsoap_white')                             = 0.75;
% objectNameToWeightMap('spongebob_squarepants_fruit_snaks')          = 0.75;
% objectNameToWeightMap('nature_valley_sweet_and_salt_almond')        = 0.75;
objectNameToWeightMap(objectNameToNumberMap('paper_plate'))                                = 5.0;
% 
% objectNameToWeightMap('pillow')                                     = 0.75;
% objectNameToWeightMap('sink')                                       = 0.75;
% objectNameToWeightMap('dining-table')                               = 0.75;
%objectNameToWeightMap('chair')                                      = 5.0;
% objectNameToWeightMap('remote')                                     = 0.75;
% 


src_dir         = '/home/reza/work/label_props/';
%the dir. where store the rgb and depth file
img_dir         = [src_dir video_name '/jpg_rgb/'];
depth_dir       = [src_dir video_name '/high_res_depth/'];

%super pixel dir.,where store the superpixels
spxl_dir        = [src_dir video_name '/spM/sp/'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nLabel = 51;
nLabel = 85;

% smoothness flag
IS_SMOOTHNESS   = true;
smoothness_cost = 0.5;

% label_dir       = [src_dir video_name '/active_vision_labels/'];
label_dir       = [src_dir video_name '/label_' video_name '/'];

if (~IS_SMOOTHNESS)
    label_dir_pred  = [src_dir video_name '/label_pred_geom_only_' num2str(nLabel) '/'];
else
    
    if (~IS_SLIDING_WINDOW)
        label_dir_pred  = [src_dir video_name '/label_pred_geom_only_' num2str(nLabel) '_with_smoothness_' num2str(smoothness_cost) '/'];
    else
        label_dir_pred  = [src_dir video_name '/label_pred_geom_only_' num2str(nLabel) '_with_smoothness_' num2str(smoothness_cost) '_sliding_window/'];
    end
    
end

if (~exist(label_dir_pred, 'dir'))
    mkdir(label_dir_pred);
end



%**************************************************************************
% save_dir_unary  = [src_dir video_name '/unary/'];
load(fullfile(src_dir, video_name, 'allKeyframes.mat'), 'trainKeyframes');
keyframes = trainKeyframes;
clear trainKeyframes;

% kfList                      = {keyframes{1:11}};
kfList                      = {keyframes{1:end}};
windowLen                   = length(kfList);

load(fullfile(src_dir, video_name, 'intrinsic.mat'));
load(fullfile(src_dir, video_name, 'allframes-extrinsics.mat'), 'allframes', 'extrinsicsC2W', 'noRt'); % extrinsics from camera 2 world coordinates
worldpc_dir     = fullfile(src_dir, video_name, 'worldpc');


%**************************************************************************
%%% Reza: 02/2018
%%% Gather all the frames for which we want to propagate labels to

allFileNames = dir([spxl_dir '*.mat']);
allFileNumbers = cell(1, length(allFileNames));
for iF=1:length(allFileNames)
   curFileNumber = allFileNames(iF).name(1:end-4); % last two digits: 03 means raw-depth image (superpixel saved by the raw-depth image name)
   allFileNumbers{iF} = curFileNumber;
   
end


%**************************************************************************
%%% Reza: 02/2018
%%% some frames don't possess (R,t) (missed out on reconstruction by Phil)

noRtFrames = {};
idx = find(noRt == 1);
for iF=1:length(idx)
    noRtFrames = cat(2, noRtFrames, allframes{idx(iF)});
end

% start = 2;
%start = 12; % chair-table mix up with small objects on top
%start = 1104; % frame with occluded wall projected on couch
%start = 5; % frame with occluded door projected on refrigerator

%for nn = start:length(allFileNumbers)    
for nn = start:finish

    disp(['processing ' num2str(nn) '/' num2str(finish)]);
% for nn = start:500  

      
    % the previous frame name
    fileNameP = allFileNumbers{nn};
    fileNameP = fileNameP(1:end-2);
        
    % the next frame name %j=n+step;    
    fileNameC = allFileNumbers{nn+1};
    fileNameC = fileNameC(1:end-2);
                    
    isEmptyRt = isempty( find(strcmp(noRtFrames, fileNameC) == 1) );
    if isEmptyRt
        fprintf([num2str(nn) ') processing ' fileNameC '\n']);
    else
        fprintf([num2str(nn) ') discarding processing (no Rot, Trans) for ' fileNameC '\n']);
        continue;
    end
    
    
    if exist(fullfile(label_dir_pred, [fileNameC , labelExtension, labelFileType]))
        fprintf([num2str(nn) ') exists for ' fileNameC '\n']);
        continue;        
    end
    
    %load super pixels
    spxl_file1              = fullfile(spxl_dir, [fileNameP, superpixelExtension, superpixelFileType]);
    sp1                     = load(spxl_file1);
    limPre                  =  sp1.sp;  %previous superpixels
    spxl_file2              = fullfile(spxl_dir, [fileNameC, superpixelExtension, superpixelFileType]);
    sp2                     = load(spxl_file2);
    limCur                  =  sp2.sp;  %'this' superpixels
    
    %get the number of superpixels per frame
    spixelNumPre = max(limPre(:)); %number of superpixels in previous frame
    spixelNumCur = max(limCur(:)); %number of supeerpixels in 'this' frame
        
    %load the rgb image
%     rgbP         = imread([img_dir  'rgb_' fileNameP '.png']);
    rgbP         = imread(fullfile(img_dir, [fileNameP, rgbExtension, rgbFileType]));
    rgbC         = imread(fullfile(img_dir, [fileNameC, rgbExtension, rgbFileType]));    
    
    % FIND THE VALID CROPPED INDICES
    valid               = zeros(size(rgbP,1), size(rgbP,2));
    valid(y1:y2,x1:x2)  = 1;
    validIndex          = find(valid == 1);
    clear valid;
    rgbP                = rgbP(y1:y2,x1:x2,:); %RGB previous
    rgbC                = rgbC(y1:y2,x1:x2,:); %RGB this
    
    ncols       = (x2-x1)+1; %num of columns
    c           = ncols;
    nrows       = (y2-y1)+1; %num of rows
    r           = nrows;    
%     [xc, yc]    = meshgrid(1:ncols, 1:nrows);
    
    
    
    %load the label file
    %tmpName = [fileNameP, rgbExtension];
    isKeyframe = find( strcmp(keyframes, fileNameP) == 1 );
    if ~isempty(isKeyframe)
        labelPpath = fullfile(label_dir, [fileNameP, labelExtension, labelFileType]);%label of the key frame
        if (1)%(nLabel == 17)            
            labelP = load(labelPpath, 'mapLabel');
            labelP = labelP.mapLabel;
        else
            
        end

    else
%         %label of the non-key frame,which get by propagated in the previous step       
%         load(fullfile(label_dir_pred, [fileNameP, labelExtension, labelFileType]), 'smoothedPredCp');
%         labelP = smoothedPredCp;
%         labelP = labelP - 1;
%         clear smoothedPredCp;
        
    end
        
    %if it is groundtrunth label, need to be cropped
    if ~isempty(isKeyframe)
        labelP = labelP(y1:y2,x1:x2,:);
    end
    
    
    
    % RGB = RGB(:,validIndex);

    %**************************************************************************
    %%% Reza: 02/2018
    %%% %%% 3D point-cloud in world-coordinate-space (wc) needs to converted into current frame's camera-coordinate-space (cc)
    % pre-processing for 3D point cloud's based energy term        
    extrinsicIndex = find(strcmp(allframes, fileNameC) == 1); % TO DO: Change the 'allframes' with adding the extension of rgb(01)
    Rc2w = extrinsicsC2W(1:3,1:3, extrinsicIndex);
    Tc2w = extrinsicsC2W(1:3,4, extrinsicIndex);
    
    % single data-structure to save relevant information per key frame
    XYZcameraAll(windowLen)     = struct('projX', [], 'projY', [], 'label', [], 'frameNum', [], 'frameSize',-1);
%     singleFrameSizes            = zeros(windowLen, 1);        
%     XYZworldAll                 = [];
%     XYZlabelAll                 = [];
%     XYZframeAll                 = [];   
    

    %**********************************************************************
    %%% Reza: 02/2018
    %%% nearby 'windowLen' labeled frames for propagation

    if (IS_SLIDING_WINDOW)
        windowLen = 10;
        kfList = keyframes; % override the whole frames
        kfIndexList = zeros(1, length(allframes));
        for ikfList=1:length(kfList)        
            kfIndexList( find(strcmp(allframes, keyframes{ikfList})) ) = 1;
        end

        idxall = find(kfIndexList == 1);
        idxcurr = find(strcmp(allframes, fileNameC) == 1);
        tmp1 = idxall-idxcurr;

        [~, ind] = min(abs(tmp1));
        leftwindow = [];

        if (ind - round(windowLen/2)) > 0
            leftwindow = idxall(( ind - round(windowLen/2) ):ind-1);
        else
            leftwindow = idxall(1:ind-1);
        end

        rightwindow = []; % includes the 'ind'
        if ((round(windowLen/2) + ind) <= length(idxall))
            rightwindow = idxall(ind:ind+round(windowLen/2));
        else
            rightwindow = idxall(ind:end);
        end

        leftwindow
        rightwindow
        windowKeyframeIndex = [leftwindow rightwindow];
        windowKeyframeNames = {};

        for iw=1:length(windowKeyframeIndex)
            windowKeyframeNames = cat(2, windowKeyframeNames, allframes{windowKeyframeIndex(iw)});
        end



        kfList = windowKeyframeNames;
    end
    
    %**********************************************************************    
    for ikfList=1:length(kfList)

%         tmpFileName = fullfile(worldpc_dir, [fileNameC, worldpclExtension, worldpclFileType]);
%         load(tmpFileName, 'XYZworld', 'valid');  % valid index is used to pick only those label-pixels that have XYZworld coordinate  
        
        tmpFileName = fullfile(worldpc_dir, [kfList{ikfList}, worldpclExtension, worldpclFileType]);        
        load(tmpFileName, 'XYZworld', 'valid');  % valid index is used to pick only those label-pixels that have valid XYZworld coordinate  
        %**********************************************************************
        labelPpath = fullfile(label_dir, [kfList{ikfList}, labelExtension, labelFileType]);%label of the key frame  
        tmpLabelP = load(labelPpath, 'mapLabel');
        tmpLabelP = tmpLabelP.mapLabel;         
        if max(tmpLabelP(:)) > nLabel            
            error(['incorrect number of labels in the ground truth : ' num2str(max(tmpLabelP(:))) '>' num2str(nLabel) ]);
        end
        tmpLabelP = tmpLabelP(y1:y2,x1:x2,:);

        % Reza: 02/2018
        % worldpc is generated only on the valid indices of the 'filled-depth' (empty depth around the sides and other areas) 
        % hence labels should also be extracted on those indices            
        tmpLabelP = tmpLabelP(valid);
        if (length(XYZworld) ~= length(tmpLabelP))
            error(['''XYZworld'' should have same number of 3D points as there are pixels in the ''mapLabel'' : ' num2str(length(XYZworld)) '~=' num2str(length(tempLabelP))]);
        end
        
        %**********************************************************************
        %*** Reza: 02/2018        
        XYZcamera         = bsxfun(@minus, Rc2w'*Tc2w, Rc2w'*XYZworld); % x=(Rc2w')*X-(Rc2w')*(Tc2w)
        XYZcamera         = XYZcamera';    
        
        %******************************************************************
        %*** Reza: 02/2018
        % occlusion reasoning:
        % consider only those 3D points that are
        % closer to the camera along the ray casted from the camera towards
        % the pixel where it intersects in the image plane
        
        %******************************************************************
        debug_projection
        %continue;
        %*** Reza: 02/2018
        % visibility reasoning:
        % discard the 3D points after projecting into the current frame whose
        % z-component is positive (indicates that in camera coordinate the 3D points are behind the camera)
        
        %******************************************************************
%         focal_length_x = K(1,1);
%         focal_length_y = K(2,2);
%         center      = [K(1,3) K(2,3)];
%         projX       = [];
%         projY       = [];   
%         %projIndices = [];    
% 
%         %%%
%         isClippingBehindCamera = 1;
%         if (isClippingBehindCamera)
%             frontOfCameraIndex  = find(XYZcamera(:,3) < 0);
%             XYZcamera           = XYZcamera(frontOfCameraIndex,:);
%             tmpLabelP           = tmpLabelP(frontOfCameraIndex);                    
%         end
% 
%         %%%
%         % clipping on the image coordinate space
%         for jj=1:size(XYZcamera,1)
%             projX(jj)=round((XYZcamera(jj,1)*focal_length_x)/XYZcamera(jj,3) + center(1)) - (x1-1);
%             projY(jj)=round((XYZcamera(jj,2)*focal_length_y)/XYZcamera(jj,3) + center(2)) - (y1-1);        
%         end
% 
%         tmpIndex = find((projX > 0 & projX <= x2) & (projY > 0 & projY <= y2)); % CHANGE THE x2 and y2 later on with parameter value
%         XYZcameraAll(ikfList).projX    = projX(tmpIndex);
%         XYZcameraAll(ikfList).projY    = projY(tmpIndex);
%         
%         % transfer the label from the the image space
%         XYZcameraAll(ikfList).label    = tmpLabelP(tmpIndex);
%         % frame no
%         XYZcameraAll(ikfList).frameNum  = kfList{ikfList}; 
%         % total no of valid 3D points from this frame
%         %XYZcameraAll(ikfList).frameSize = length(XYZcamera);
%         XYZcameraAll(ikfList).frameSize = length(projX(tmpIndex));
%         
%         
%         
%         vis = 0;
%         if (vis)
%             rgbLabel = imread(fullfile(img_dir, [kfList{ikfList}, rgbExtension, rgbFileType]));           
%             figure; imagesc(rgbC); title('current frame');
%             figure; imagesc(rgbLabel); title('the keyframe')
%             figure; imagesc(rgbC); title('labeled pcl of a keyframe projected'); hold on; plot(projX, projY, '+g');
%             
%             pause(1); %close(f3);
%             close all;
%             %XYZcamera = XYZcamera;plot3(XYZcamera(1:500:end,1), XYZcamera(1:500:end,2), XYZcamera(1:500:end,3), '+g')
%         end

        XYZcameraAll(ikfList).projX    = projX;
        XYZcameraAll(ikfList).projY    = projY;
        
        % transfer the label from the the image space
        XYZcameraAll(ikfList).label    = tmpLabelP;
        % frame no
        XYZcameraAll(ikfList).frameNum  = kfList{ikfList}; 
        % total no of valid 3D points from this frame
        %XYZcameraAll(ikfList).frameSize = length(XYZcamera);
        XYZcameraAll(ikfList).frameSize = length(projX);
        
        disp([num2str(ikfList) '/' num2str(length(kfList)) ' keyframes processed ...']);
        % debug for start-frame=5 occluded part got projected into missing
        % depth region (door on refridgerator)
        %if (~isempty(find(tmpLabelP == 37)))            
        %    keyboard;
        %end
        
        % debug for startframe=1104 occluded part wall got projected onto couch
        %figure; imagesc(projMaskWithoutOcclusion); title('proj with occluded part removed  within valid depth');
        %rgbLabel = imread(fullfile(img_dir, [kfList{ikfList}, rgbExtension, rgbFileType]));           
        %figure; imagesc(rgbLabel); title('keyframe'); pause; close;
        
        %******************************************************************
%         XYZcameraAll      = cat(2, XYZcameraAll, XYZcamera);            % concatenate into the existing camera coordinates of the current-frame
        
        
%         pts = bsxfun(@minus, Rc2w'*Tc2w, Rc2w'*XYZworldAll);          % x=(Rc2w')*X-(Rc2w')*(Tc2w)
%         pts = pts';    
%         %XYZworld = XYZworld(:,validIndex);               
%         XYZworldAll = cat(2, XYZworldAll, XYZworld); % concatenate into the existing world coordinates of the previous frames


%         % transfer the label from the the image space
%         XYZlabelAll = cat(2, XYZlabelAll, tmpLabelP(:)');

%         % frame no
%         XYZframeAll = cat(2, XYZframeAll, str2num(kfList{ikfList})*ones(1,length(tmpLabelP(:))));        

% %         singleFrameSizes(ikfList) = length(XYZworld);
%         singleFrameSizes(ikfList) = length(XYZcamera);


    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    ;
    
% %     % project the labels back to the frame
% %     focal_length_x = K(1,1);
% %     focal_length_y = K(2,2);
% %     center      = [K(1,3) K(2,3)];
% %     projX       = [];
% %     projY       = [];   
% %     projIndices = [];    
% %     
% %     for jj=1:size(pts,1)
% %         projX(jj)=round((pts(jj,1)*focal_length_x)/pts(jj,3) + center(1)) - (x1-1);
% %         projY(jj)=round((pts(jj,2)*focal_length_y)/pts(jj,3) + center(2)) - (y1-1);        
% %     end    
% %     
% % %     tmpIndex = find((projX > 0 & projX <= size(labelP,2)) & (projY > 0 & projY <= size(labelP,1))); % CHANGE THE size(labelP,*) later on with parameter value
% % %     projIndices = cat(2, projIndices, tmpIndex');
% % %     
% % %     projX = projX(projIndices);
% % %     projY = projY(projIndices);    
% % %     projL = XYZlabelAll(projIndices);
% % %     projF = XYZframeAll(projIndices);
% % %     save('XYZworldAll.mat', 'XYZworldAll', 'XYZlabelAll', 'XYZframeAll');    
% % %     clear XYZworldAll XYZlabelAll pts XYZframeAll;
% %     
% %     vis = 0;    
% % %     if (vis)
% % %         
% % %         croppedRGB = rgbC;
% % %         f2 = figure; imagesc(croppedRGB); title(['projected from global point cloud' fileNameC]);
% % %         position1 = get(f2, 'OuterPosition');
% % %         set(f2, 'OuterPosition', [10 position1(2:4)]);
% % %         hold on;
% % %         tmpIndex = find(projL == 1);
% % %         plot(projX(tmpIndex), projY(tmpIndex), '.c');        
% % %         tmpIndex = find(projL == 2);
% % %         plot(projX(tmpIndex), projY(tmpIndex), '.r');        
% % %         tmpIndex = find(projL == 3);
% % %         plot(projX(tmpIndex), projY(tmpIndex), '.g');        
% % %         tmpIndex = find(projL == 4);
% % %         plot(projX(tmpIndex), projY(tmpIndex), '.b');
% % %         %keyboard;
% % % 
% % %     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % pixel-wise unary data term based on 3D geometric projection
    
    pwDataTermG = zeros(r,c,nLabel+1); % default zero to give precedence over flow-based score on the regions where we have no projection
    
    for i= 1:spixelNumCur
        
        %find the superpixel of index i
        seg         = limCur==i;
        
        %xSeg2d = xc(seg); ySeg2d = yc(seg); %x-coordinate %y-coordinate            
        segIndex    = find(limCur == i);
        
        geomScores      = zeros(nLabel+1, windowLen);
        isProjected     = zeros(nLabel+1, windowLen); % Boolean flag to determine whether a label appears within a current projection
        
        
        for jFrame=1:windowLen
        
            % can't assume all frames has same 3D points since Phil's reconstruction gives sparse point cloud            
%             endOffset       = startOffset+singleFrameSizes(jFrame)-1;
            
            
            % get j-th frame pcl projection into the current image space
%             curProjX        = projX(startOffset:endOffset);
%             curProjY        = projY(startOffset:endOffset);
%             curLabel        = XYZlabelAll(startOffset:endOffset);
%             curFrame        = XYZframeAll(startOffset:endOffset);
            
            curProjX        = XYZcameraAll(jFrame).projX;
            curProjY        = XYZcameraAll(jFrame).projY;
            curProjL        = XYZcameraAll(jFrame).label;
            curProjF        = XYZcameraAll(jFrame).frameNum;
            
            
            % find the indices that fall within the range of the image 
            % (REZA: 02/03/18 already prunned based on (3D camera-coordinate + image-coordinate))            
%             tmpIndex        = find((curProjX > 0 & curProjX <= x2) & (curProjY > 0 & curProjY <= y2)); % CHANGE THE x2+y2 later on with parameter value
%             projIndices     = tmpIndex';
% 
%             curProjX    = curProjX(projIndices);
%             curProjY    = curProjY(projIndices);    
%             curProjL    = curLabel(projIndices);
%             curProjF    = curFrame(projIndices);
            
    
            % find the intersected projected pixels and current pixels within the superpixels
            projIndex                         = sub2ind([r, c], curProjY, curProjX);            
            [cIndex, iSegIndex, IprojIndex]   = intersect(segIndex, projIndex);        
            labels                            = curProjL(IprojIndex);

            vis = 0;
            if (vis)                
                xCoords     = curProjX(IprojIndex);
                yCoords     = curProjY(IprojIndex);                
                f3 = figure; imagesc(rgbC);
                %position3 = get(f3, 'OuterPosition');
                %set(f3, 'OuterPosition', [position1(3)+230 position3(2:4)]);
                hold on; plot(xCoords, yCoords, '+g');         
                % [spxl_r, spxl_c] = ind2sub([r, c], segIndex); % superpixel visualizaton
                % hold on; plot(spxl_c, spxl_r, '+r');
                pause; close(f3);  
                
            end

            for ii=0:nLabel
                % fraction of pixel inside the superpixel that can be explained by the label (ii+1). used as geometric unary scores per pixel
                if (~isempty(find(labels == ii)))

                    sizeWithLabelii = length(find(labels == ii));
                    curGeomScore = sizeWithLabelii/length(labels);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % some view projects into the superpxl more than others
                    % this weight balances this factor
                    projWeight = length(labels)/length(segIndex);                    
                    
                    
                    %******************************************************
                    if (HAS_OBJECT_WEIGHT)
                        objectWeight = 1.0;
                        if (~isempty(find(importantObjectIds == ii)))
                           %objectWeight = 5.0; 
                           objectWeight = objectNameToWeightMap(num2str(ii));
                        end
                        %******************************************************
                        geomScores(ii+1, jFrame) = objectWeight*projWeight*curGeomScore;
                    
                    else
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                              
                        geomScores(ii+1, jFrame) = projWeight*curGeomScore;
                    end                    
                    % more than 5 percent pixels are explained by a label is considered, others are considered as noise (since we are doing mean over multiple frames)
                    if (curGeomScore > 0.05) 
                        isProjected(ii+1, jFrame) = 1; % this label is present within the superpixel when projected from j-th frame
                    end
                    
                end

            end
            
            % update the startOffset for next frame's operation
%             startOffset = endOffset + 1;


        end
        
%         if (i == 132 || i == 168  || i == 192)
%             keyboard;
%         end
        
        for ii=0:nLabel
            curPwDataTermG          = pwDataTermG(:,:,ii+1);
            % average of the scores from frames where a projection was
            % found
            idx = find(isProjected(ii+1,:));
            if (~isempty(idx))
                curScore                = -mean(geomScores(ii+1,idx));            
                curPwDataTermG(seg)     = curScore;                     % more negative is better
                pwDataTermG(:,:,ii+1)   = curPwDataTermG;
            end

        end           
        
        fprintf('Finished processing %d/%d superpixels\n', i, spixelNumCur);
        
    end    
    
    clear labels seg segIndex;
    clear XYZcameraAll;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOW-BASED INFO        
%     if (0)
%         %to store featurs for 'this' superpixels in cell
%         segCur =  cell(spixelNumCur,1); 
% 
%         %initialize parameters of superpixels for the 'this' frame 
%         %%in the form of cells 
%         for i= 1:spixelNumCur
% 
%             %find the superpixel of index i
%             seg = limCur==i;
%             xSeg2d = xc(seg); ySeg2d = yc(seg); %x-coordinate %y-coordinate 
% 
%             %initialize the label to the default -1;not assigned
%             segCur{i}.label = -1;
% 
%             xySegC = [xSeg2d ySeg2d];
%             segCur{i}.seg = seg;
%             segCur{i}.coor = xySegC;
%             segCur{i}.size = (sum(seg(:)));%total number of pixels
% 
%             minX = min(xSeg2d(:)); minY = min(ySeg2d(:));
%             %        minZ = min(zSeg2d(:));        
%             maxX = max(xSeg2d(:)); maxY = max(ySeg2d(:));
%             %        maxZ = max(zSeg2d(:));        
%             w = maxX - minX; h = maxY - minY; %x, width %y, height 
%             %        d = maxZ - minZ; %z        
%             segCur{i}.whd = [w;h]; segCur{i}.XYmin = [minX minY ]; segCur{i}.XYmax = [maxX maxY ];               
%             segCur{i}.RGB = [rgbCurR(seg) rgbCurG(seg) rgbCurB(seg)];
%             segCur{i}.mean_centroid_2D= [mean(xSeg2d(:)) mean(ySeg2d(:))];
% 
%             %the index of the superpixel in the 5th frame 'after' this superpixel associated with
%             segCur{i}.after =0;
%             %the index of the superpixel in the 5th frame 'before' this superpixel associated with
%             segCur{i}.before =0;
% 
%         end
% 
% 
% 
%         [xc, yc] = meshgrid(1:ncols, 1:nrows);
% 
%         %superpixel level labeling from pixel level
%         labelpr = zeros(r,c);
% 
%         %to store featurs for 'this' superpixels in cell
%         segPre =  cell(spixelNumPre,1); 
% 
%         %initialize parameters of superpixels for the 'previous' frame in the form of cells 
%         for i= 1:spixelNumPre
% 
%             seg = limPre==i;
%             xSeg2d = xc(seg);
%             ySeg2d = yc(seg);
%             %       zSeg2d = depthP(seg);
% 
%             xySegC = [xSeg2d ySeg2d];
%             segPre{i}.seg = seg; segPre{i}.coor = xySegC; segPre{i}.size = (sum(seg(:)));
% 
%             %assign the LABEL of GT to each superpixel, GT label is pixel-wise
%             labelSeg = labelP(seg);
%             %suml =[sum(labelSeg==0); sum(labelSeg==1); sum(labelSeg==2); sum(labelSeg==3); sum(labelSeg==4)];
%             suml = [];
%             for ii=0:nLabel
%                 suml =[suml; sum(labelSeg==ii)];
%             end
% 
%             %choose the label which occupies the most in the superpixel
%             label = find(suml==max(suml));
% 
%             %in case size(label,1)<=1
%             if size(label,1)>1
%                 label = max(label);
%             end
%             label = label-1;
%             segPre{i}.label = label;
% 
%             %the annotation on superpixels
%             labelpr(limPre==i) = segPre{i}.label;
% 
%             minX = min(xSeg2d(:)); minY = min(ySeg2d(:));
%             %      minZ = min(zSeg2d(:));        
%             maxX = max(xSeg2d(:)); maxY = max(ySeg2d(:));
%             %       maxZ = max(zSeg2d(:));        
%             w = maxX - minX; h = maxY - minY; %y %x        
%             %       d = maxZ - minZ; %z
% 
%             segPre{i}.whd = [w;h]; segPre{i}.XYmin = [minX minY ]; segPre{i}.XYmax = [maxX maxY ];        
%             segPre{i}.RGB = [rgbPreR(seg) rgbPreG(seg) rgbPreB(seg)];
%             segPre{i}.mean_centroid_2D= [mean(xSeg2d(:)) mean(ySeg2d(:))];
%             %the index of the superpixel in the 5th frame 'before' this superpixel associated with
%             segPre{i}.before =0;
%             %the index of the superpixel in the 5th frame 'after' this superpixel associated with
%             segPre{i}.after =0;
% 
%         end
%     
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    pwDataTermC = zeros(r,c,nLabel+1);
    pwDataTermT = zeros(r,c,nLabel+1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOW-BASED INFO    
%     if (0)
%         %find associated candidated superpixels
%         for i = 1:spixelNumCur
% 
%             seg = limCur==i;
% 
%             if sum(seg(:))==1
%                 continue;
%             end
% 
%             %the u,v of the flow, u-Xderection, v-Yderection
%             uf = f(:, :,1);
%             vf = f(:, :,2);
%             u = uf(seg);
%             v = vf(seg);
% 
%             xySeg  = segCur{i}.coor ;
%             xSeg2d = xySeg(:,1);
%             ySeg2d = xySeg(:,2);
% 
% 
%             %predicted coordinates
%             %coordinate  x, y add optical flow u, v correspondingly
%             segPredict = [xSeg2d+u, ySeg2d+v];
% 
% 
% 
%             %check the if the the predicted pixel positiones is across the
%             %image boundary
%             xnew = segPredict(:,1);
%             ynew = segPredict(:,2);
%             xnew(xnew>ncols)=ncols;
%             xnew(xnew<1)=1;
%             ynew(ynew>nrows)=nrows;
%             ynew(ynew<1)=1;
% 
% 
%             segPredict = [xnew ynew];
%             %round the predicted coordinates, which is the form of float
%             segPredictR = round(segPredict);
%             %compute the coordinate index, i.e. transfer two dimension index to
%             %one dimension index
%             segPredictINdex = (segPredictR(:,1)-1)*r+segPredictR(:,2);
%             %the predict mask
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             maskPredit = zeros(r,c);        % initialize
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             segPredictINdex = unique(segPredictINdex);
%             maskPredit(segPredictINdex)=1;
% 
% 
%             %get all the indexes of superpixels in the 'Previous' farmes which
%             %are intersected(ovelapped) with the predicted area
%             overlap = limPre(segPredictINdex);
%             %the index of the intersected superpixels
%             segindex = unique(overlap);
% 
%             %compute the IOU for all superpixels intersected 
%             indnum = length(segindex); %the number of the intersected
%             ratio = zeros(indnum,1);
%             lbls = zeros(indnum,1);
% 
%             for m = 1:indnum
%                 in = segindex(m);
%                 %compute the IOU
%                 %ratio(m)=sum(overlap(:)==in)/(sum(maskPredit(:)==1)+sum(limPre(:)==in)); % IT IS NOT IoU
% 
%                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 unionPxls = [find(maskPredit(:)==1); find(limPre==in)];
%                 unionPxls = unique(unionPxls);
%                 ratio(m)  = sum(overlap(:)==in)/length(unionPxls);                      
%                 img_limPre = zeros(r,c);
%                 img_limPre(find(limPre(:)==in)) = 1;
%                 lbls(m) = unique(labelpr(find(img_limPre == 1)));           
%                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
%     %             % compute the label of each overlapped superpixel
%     %             overlap_mask = zeros(r,c);
%     %             overlap_mask(segPredictINdex) = limPre(segPredictINdex); 
%     %             img_overlap(find(overlap_mask==in)) = 1;        
% 
%             end
% 
%     % % %         %the maximal IoU
%     % % %         rIOU = max(ratio);
%     % % %         
%     % % %         %the tatol num of pixels in the prediction
%     % % %         lenPrdict = sum(maskPredit(:)==1);
%     % % %         
%     % % %         %find the candidate superpixels which is 
%     % % %         %the superpixels in 'previous' frame with the highest IoU
%     % % %         k = segindex(find(ratio==max(ratio)));%the choosen index(es)
%     % % %         
%     % % %         
%     % % %         %the case the number of IOU candidates are >1, choose the one with
%     % % %         %minial size difference among them
%     % % %         if size(k,1)>1
%     % % %             
%     % % %             diffSize =  abs(lenPrdict - sum(limPre(:)==k(1)));
%     % % %             ck = k(1);
%     % % %             
%     % % %             for j=2:size(k,1)
%     % % %                 
%     % % %                 diffs = abs(lenPrdict - sum(limPre(:)==k(j)));
%     % % %                 
%     % % %                 if diffs < diffSize
%     % % %                     diffSize = diffs;
%     % % %                     ck = k(j);
%     % % %                 end
%     % % %                 
%     % % %             end
%     % % %             k = ck; %the choosen index
%     % % %         end
% 
% 
% 
%             %assign the predicted label to the current frame
%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             if segCur{i}.label == -1
%                 pColorDist = zeros(nLabel+1,1);
%                 pTextDist = zeros(nLabel+1,1);
%                 for ii=0:nLabel
% 
%                     % for each label set the unary scores (over lap region can intersect with many superpixels with the same label. pick the most similar one)
%                     idx = find(lbls == ii);
%                     cScores = zeros(length(idx),1);
%                     distColors = zeros(length(idx),1);
%                     ratioMdistColor = zeros(length(idx),1);
%                     distTexts = zeros(length(idx),1);
%                     ratioMdistText = zeros(length(idx),1);
%                     for jj=1:length(idx)
%                         cRatio  = ratio(idx(jj));
%                         cLabel  = lbls(idx(jj));
%                         cSpxl   = segindex(idx(jj));
% 
%                         colHistC = chCur(i,:);
%                         colHistPre = chPre(cSpxl,:);
%                         %compute the chi-square distance of histograms
%                         distColor = pdist_2( colHistC, colHistPre, 'chisq');
%                         distColors(jj) = exp(-distColor);                       %the bigger this value is, the more similiar 
%                         ratioMdistColor(jj) = distColors(jj)*cRatio;
% 
% 
%                         textHistC = ttCur(i,:);
%                         textHistPre = ttPre(cSpxl,:);
%                         %compute the chi-square distance of histograms
%                         distText = pdist_2( textHistC, textHistPre, 'chisq');
%                         distTexts(jj) = exp(-distText);                    
%                         ratioMdistText(jj) = distTexts(jj)*cRatio;
%                     end
% 
% 
%                     if (~isempty(ratioMdistColor) || ~isempty(ratioMdistText))
%                         pColorDist(ii+1) = -max(ratioMdistColor)-1; % take the maximum value
%                         pTextDist(ii+1)  = -max(ratioMdistText)-1;
%                     else
%     %                     pColorDist(ii+1) = 1; % large number for label not present
%     %                     pTextDist(ii+1) = 1; % large number for label not present
%                     end
% 
%                 end
% 
%                 segCur{i}.pColorDist = pColorDist;            
%                 segCur{i}.pTextDist = pTextDist;    
% 
%                 % fill in the pixels within the superpixel same score as data term for later CRF stage
%                 for ii=0:nLabel
%                     % color unary scores per pixel
%                     curPwDataTermC = pwDataTermC(:,:,ii+1);
%                     curPwDataTermC(seg) = pColorDist(ii+1);
%                     pwDataTermC(:,:,ii+1) = curPwDataTermC;
% 
%                     % texture unary scores per pixel
%                     curPwDataTermT = pwDataTermT(:,:,ii+1);
%                     curPwDataTermT(seg) = pTextDist(ii+1);
%                     pwDataTermT(:,:,ii+1) = curPwDataTermT;
% 
%                 end
%                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%             end
% 
% 
%         end
%     
%     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % prepare the pixel-wise unary potential for the inference
        
%     if (~exist(save_dir_unary, 'dir'))
%         mkdir(save_dir_unary);
%     end
    
    if (vis)        
        figure; imagesc(pwDataTermG(:,:,1))
        figure; imagesc(pwDataTermG(:,:,2))
        figure; imagesc(pwDataTermG(:,:,3))
        figure; imagesc(pwDataTermG(:,:,4))
        figure; imagesc(pwDataTermG(:,:,5))

        figure; imagesc(pwDataTermC(:,:,1))
        figure; imagesc(pwDataTermC(:,:,2))
        figure; imagesc(pwDataTermC(:,:,3))
        figure; imagesc(pwDataTermC(:,:,4))
        figure; imagesc(pwDataTermC(:,:,5))
        
        figure; imagesc(Dc(:,:,1))
        figure; imagesc(Dc(:,:,2))
        figure; imagesc(Dc(:,:,3))
        figure; imagesc(Dc(:,:,4))
        figure; imagesc(Dc(:,:,5))
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    %%%%%    graph-cut optimization for smoothing the prediction
    LARGE_NUM = 1234567;
    % convert the likelihood map into negative log likelihood for data term in graph cut.
    %foregroundProb(foregroundProb == inf) = LARGE_NUM; foregroundProb = -log(foregroundProb);
    %Dc(:,:,1) = foregroundProb;

    % convert the likelihood map to negative log likelihood that will be used as data term for graph cut.
    %backgroundProb(backgroundProb == inf) = LARGE_NUM; backgroundProb = -log(backgroundProb);
    %Dc(:,:,2) = backgroundProb;

    weightC = 0.0;
    weightG = 1.0;
    Dc = weightC*pwDataTermC + weightG*pwDataTermG;
    Dc = Dc + nLabel; % with zero being most positive the graph-cut inference gives no output; hence add offset to make all score positive
    % smoothness term: 
    % constant pairwise term   
    Sc  = ones(nLabel+1) - eye(nLabel+1);
    

    % smoothness or just unary only
    if (IS_SMOOTHNESS)
        gch = GraphCut('open', Dc, smoothness_cost*Sc);
    else
        gch = GraphCut('open', Dc, 0.0*Sc);
    end
    
    display(['Graphcut running on frame ' fileNameC]);
    tic; [gch, L] = GraphCut('expand',gch); toc;
    gch = GraphCut('close', gch);
    smoothedPredCp = L;
    if (0)
        %close(f1);        
        %f2 = figure;
        f1 = figure;
        position1 = get(f1, 'OuterPosition');
        clf(f1);
        subplot(1,3,1); imagesc(rgbC); title(['rgb-frame-' fileNameC]);
        subplot(1,3,2); imagesc(labelP); title(['previous-label-' fileNameP]);
        subplot(1,3,3); imagesc(smoothedPredCp); title(['propagated label-' fileNameC]);    
        pause(3); %f1 = f2;
    end
    smoothedPredCp = smoothedPredCp+1;

    
%     % constrast sensitive pairwise term
%     % spatialy varying part
%     % [Hc Vc] = gradient(imfilter(rgb2gray(im),fspecial('gauss',[3 3]),'symmetric'));
%     [Hc Vc] = spatial_cues(double(rgbC));           
%     gch     = GraphCut('open', Dc, 100*Sc, exp(-Vc*(nLabel+1)), exp(-Hc*(nLabel+1)));
%     [gch L] = GraphCut('expand',gch);
%     gch     = GraphCut('close', gch);
%     smoothedPredCs = L;
%     smoothedPredCs = smoothedPredCs+1;

    smoothnessParams = [2.5, 100, 5, 5];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%     imwrite(rgbC, '0077.ppm');
%     %write_data(pwDataTermC, [save_dir_unary  fileNameC '_cu']);
%     writeDataTxt(pwDataTermC, [save_dir_unary  fileNameC '_cu']);
%     save([save_dir_unary  fileNameC '_uf.mat'], 'segCur'); % save the flow-based unary


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% dense-crf inference
    
% % % %     imwrite(rgbC, 'dense_crf_tmp/rgb.ppm');
% % % %     writeDataTxt(Dc, 'dense_crf_tmp/unary');    
% % % %     M = 5;
% % % %     % pairwise parameters
% % % %     xStddevCi=3; yStddevCi = 3; weightCi = 3;	
% % % %     useColorI = 0;
% % % % 	% color depedent pairwise parameters
% % % % 	xStddevCd = 80; yStddevCd = 80; weightCd = 10;	
% % % % 	rStddevCd = 20; gStddevCd = 20; bStddevCd = 20;
% % % %     useColorD = 0;
% % % %     f = fopen('dense_crf_tmp/paramfile.txt', 'w');
% % % %     fprintf(f, '%d\n%d\n%d\n',c, r, M);    
% % % %     fprintf(f, '%d\n',useColorI);
% % % %     if (useColorI)
% % % %         fprintf(f, '%d\n%d\n%d\n',xStddevCi, yStddevCi, weightCi);  
% % % %     end    
% % % %     
% % % %     fprintf(f, '%d\n',useColorD);
% % % %     if (useColorD)
% % % %         fprintf(f, '%d\n%d\n%d\n',xStddevCd, yStddevCd, weightCd);    
% % % %         fprintf(f, '%d\n%d\n%d',rStddevCd, gStddevCd, bStddevCd);        
% % % %     end
% % % %     
% % % %     fclose(f);
% % % %     
% % % %     disp('writing the data matlab matrix into .txt file for dense-crf energy minimization');
% % % %     pause(3);
% % % %     tic, system(['./dense_random_field/densecrf/build/examples/dense_inference ' ...
% % % %                 'dense_crf_tmp/rgb.ppm ' ...
% % % %                 'dense_crf_tmp/unary.txt ' ...
% % % %                 'dense_crf_tmp/outfile.txt ' ...
% % % %                 'dense_crf_tmp/paramfile.txt']); toc
% % % %     
% % % %         
% % % %     labelPdcrf = textread('dense_crf_tmp/outfile.txt');
% % % %     labelPdcrf = reshape(labelPdcrf, [r c]);            
% % % %     figure; imagesc(labelPdcrf);
% % % %     
% % % %     delete('dense_crf_tmp/rgb.ppm');
% % % %     delete('dense_crf_tmp/unary.txt');
% % % %     delete('dense_crf_tmp/outfile.txt');
% % % %     delete('dense_crf_tmp/paramfile.txt');
% % % %     
% % % %     
    %predictedLabel = smoothedPredCp;      
    if (~exist([label_dir_pred]))
       mkdir([label_dir_pred]); 
    end
    save(fullfile(label_dir_pred, [fileNameC , labelExtension, labelFileType]), 'smoothedPredCp');
    system(['chmod 777 ' fullfile(label_dir_pred, [fileNameC , labelExtension, labelFileType])]);
    
    
end
