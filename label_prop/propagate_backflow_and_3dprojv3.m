%This script is for the lael propagation 

close all; clear;
%**************************************************************************
step = 1;

%**************************************************************************
%set the path,
%"yourfolder" should be cahanged to the path of ur folder storing these
%folders

video_name      = 'hotel_umd40';
% video_name      = 'studyroom';
% video_name      = 'hv_c6';
% video_name      = 'mit_32';

%src_dir         = '/media/New Volume_/label_prop/';
src_dir         = '/home/reza/work/label_props/';
%the dir. where store the rgb and depth file
det_dir         = [src_dir video_name '/RGB/'];

%super pixel dir.,where store the superpixels
spxl_dir        = [src_dir video_name '/super_pixels/'];
%label_dir., where to store the label files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% label_dir       = [src_dir video_name '/label/'];
% label_dir_pred  = [src_dir video_name '/label_pred_geom_only_v2/'];
% nLabel = 4;

% smoothness flag
IS_SMOOTHNESS = true;
smoothness_cost = 2.5;

%label_dir       = [src_dir video_name '/label_13plus/'];
label_dir       = [src_dir video_name '/label/'];

if (~IS_SMOOTHNESS)
    label_dir_pred  = [src_dir video_name '/label_pred_geom_only_13/'];
else
    label_dir_pred  = [src_dir video_name '/label_pred_geom_only_13_with_smoothness_' num2str(smoothness_cost) '/'];
end

if (~exist(label_dir_pred, 'dir'))
    mkdir(label_dir_pred);
end

nLabel = 13;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save_dir_unary  = [src_dir video_name '/unary/'];

%color_hist_dir,where to store the color histogram file, the color histgram
%is for each superpixels in a single image
color_hist_dir  = [src_dir video_name '/color_hist_ss/'];
%textual_hist_dir, where to store the testure histogram files, the texture
%histogram is for each superpixels in a single image
text_hist_dir   = [src_dir video_name '/texture_hist_ss/'];

flow_dir        = [src_dir video_name '/flow_back/'];
%**************************************************************************
%keyframes = [66, 76, 81, 96, 106, 121, 126];
load([src_dir video_name '/keyframes.mat'], 'keyframes');
load([src_dir video_name '/intrinsic.mat']);
load([src_dir video_name '/extrinsic.mat']); % extrinsics from camera 2 world coordinates
worldpc_dir     = [src_dir video_name '/worldpc/'];
color = [0 0 0;
        0 255 255;
        255 0 0;
        0 255 0;
        0 0 255];        
%**************************************************************************
%this loop is to propagate using the keyframe before, 
%i.e. track in the forward direction, using the reverse-flow

%for example: frame 1  is the key frame, frame 5 borrows the label from
%frame 1 using the reverse-flow(flow from the frame 5 to 1), and then the
%frame 10 borrows the label from the frame 5, and 15 borrows from 10, till
%it reaches the 'cur0' frame 
allFileNames = dir([spxl_dir '*.mat']);
allFileNumbers = zeros(1, length(allFileNames));
for iF=1:length(allFileNames)
   curFileNumber = allFileNames(iF).name(end-7:end-4);
   curFileNumber = str2num(curFileNumber);
   allFileNumbers(iF) = curFileNumber;
   
end


start = 1;
%geomUnaryWindowSize = 40;
kfIndex = 2;
for nn = 64:length(allFileNumbers)
      
    n = allFileNumbers(nn);
    %the previous frame name
    strName = sprintf('%04d',n);
        
    %the next frame name
    %j=n+step;
    j=allFileNumbers(nn+1);
    strName2 = sprintf('%04d',j);
    
    
    %filepath of these two frames above
    filenameP = [ strName ];  %previous one 
    filenameC = [ strName2 ]; %'this' one(5th frame after the previous)
            
    display(['processing ' num2str(j)]);
    
    %load super pixels
    spxl_file1                      = [spxl_dir filenameP '.mat'];
    sp1 = load(spxl_file1);
    limPre =  sp1.sp;  %previous superpixels
    spxl_file2                      = [spxl_dir filenameC '.mat'];
    sp2 = load(spxl_file2);
    limCur =  sp2.sp;  %'this' superpixels
    
    %get the number of superpixels per frame
    spixelNumPre = max(limPre(:)); %number of superpixels in previous frame
    spixelNumCur = max(limCur(:)); %number of supeerpixels in 'this' frame
    
    %cropping parameters, crop images to ramove the boarder 
    x1 = 41; x2 = 600;
    y1 = 46; y2 = 470;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOW-BASED INFO
% %     %load color histogram
% %     ch1 = load([color_hist_dir filenameP '.mat'],'color_hist_ss');
% %     chPre = ch1.color_hist_ss; %previous color histogram
% %     ch2 = load([color_hist_dir filenameC '.mat'],'color_hist_ss');
% %     chCur = ch2.color_hist_ss; %this color histogram
% %     
% %     %load texture histogram
% %     tt1 =load([text_hist_dir filenameP '.mat'],'texture_hist_ss');
% %     ttPre = tt1.texture_hist_ss; %previous texture histogram
% %     tt2 =load([text_hist_dir filenameC '.mat'],'texture_hist_ss');
% %     ttCur = tt2.texture_hist_ss; %this texture histogram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    
    %load the rgb image
    rgbP         = imread([det_dir  'rgb_' filenameP '.png']);
    
    
    % FIND THE VALID CROPPED INDICES
    valid = zeros(size(rgbP,1), size(rgbP,2));
    valid(y1:y2,x1:x2) = 1;
    validIndex = find(valid == 1);
    clear valid;
    
    rgbP         = rgbP(y1:y2,x1:x2,:); %RGB previous
    rgbC         = imread([det_dir  'rgb_' filenameC '.png']);
    rgbC         = rgbC(y1:y2,x1:x2,:); %RGB this
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOW-BASED INFO
%     %load the optical flow file   
%     %fb.mat means the reversed direction e.g, 1b.mat has flow computed from
%     %2->1, but saved as 1b.mat (Reza: I would be naming it as 2b.mat since flow source is 2 and sink at 1)
%     f_file = load([flow_dir  num2str(n)  'b.mat']);  
%     %flow
%     f = f_file.F;
%     %crop the flow
%     f = f(y1:y2,x1:x2,:);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    RgbPre_    = zeros(y2-y1+1,x2-x1+1,3);
    
    rgbPreR = rgbP(:,:,1);
    rgbPreG = rgbP(:,:,2);
    rgbPreB = rgbP(:,:,3);
    
    
    rgbCurR = rgbC(:,:,1);
    rgbCurG = rgbC(:,:,2);
    rgbCurB = rgbC(:,:,3);
    
   
    
    ncols = x2-x1+1; %num of columns
    c = ncols;
    nrows = y2-y1+1; %num of rows
    r = nrows;
    
    [xc, yc] = meshgrid(1:ncols, 1:nrows);
        
%     % suppress for generating the toy-example for the final presentation
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Reza: 05/23/18
%     
%     %load the label file
%     %if n == start %the left keyframe 
%     if ~isempty(find(keyframes == n))
%         labelPpath = [label_dir strName '.mat'];%label of the key frame
%         %load the label
%         if (nLabel == 4)
%             labelP = load(labelPpath, 'superLabel');
%             labelP = labelP.superLabel;        
% %         load('tmp.mat', 'labelP');
%         elseif (nLabel == 13)            
%             labelP = load(labelPpath, 'mapLabel13');
%             labelP = labelP.mapLabel13;
%         end
% 
%     else
%         %label of the non-key frame,which get by propagated in the previous step       
%         load([label_dir_pred strName '.mat'], 'smoothedPredCp');
%         labelP = smoothedPredCp;
%         labelP = labelP - 1;
%         clear smoothedPredCp;
%         
%     end
% 
%     
%     %if it is groundtrunth label, need to be cropped
%     %if n == start
%     if ~isempty(find(keyframes == n))
%         labelP = labelP(y1:y2,x1:x2,:);
%     end
% 
%     % suppress for generating the toy-example for the final presentation
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % pre-processing for 3D point cloud's based energy term    

    % load the all the previous frames XYXworld
    if (1)
        XYZworldAll = [];
        XYZlabelAll = [];
        XYZframeAll = [];   
        
% % %         if (0>=(j-geomUnaryWindowSize))
% % %             initFrame       = 1;         % start of the window
% % %             windowLen       = j - initFrame; % length of the window
% % %         else
% % %             
% % %             initFrame = ( j- geomUnaryWindowSize);
% % %             windowLen  = geomUnaryWindowSize;
% % %         end
% % %         
% % %         %for jFrame=initFrame:windowLen
% % %         for jFrame=1:windowLen
% % %             
% % %             %load(['.mat'], 'XYZworldAll', 'XYZlabelAll', 'XYZframeAll');
% % %             
% % %             % load the previous frames's (for which we had gt/pred label) world coordinates and project it into the% 2D image space
% % %             %tmpFileName = sprintf('%04d',(jFrame + start -1));
% % %             tmpFileName = sprintf('%04d',(jFrame + initFrame -1));
% % %             %display(['Geom. Unary: window(' num2str(jFrame) ').' tmpFileName]);            
% % %             load([worldpc_dir 'rgb_' tmpFileName '.mat']);    
% % %             XYZworld = XYZworld(:,validIndex);   
% % %             XYZworldAll = cat(2, XYZworldAll, XYZworld); % concatenate into the existing world coordinates of the previous frames
% % %             
% % %             tmpFrameNum = str2num(tmpFileName);
% % %             if ~isempty(find(keyframes == tmpFrameNum))
% % %                 labelPpath = [label_dir tmpFileName '.mat'];%label of the key frame
% % %                 %load the label
% % %                 tmpLabelP = load(labelPpath, 'superLabel');
% % %                 tmpLabelP = tmpLabelP.superLabel;         
% % %                 tmpLabelP = tmpLabelP(y1:y2,x1:x2,:);
% % %             else
% % %                 load([label_dir_pred tmpFileName '.mat'], 'smoothedPredCp');
% % %                 tmpLabelP = smoothedPredCp-1;
% % %             end
% % %             % transfer the label from the the image space
% % %             XYZlabelAll = cat(2, XYZlabelAll, tmpLabelP(:)');
% % % 
% % %             % frame no
% % %             XYZframeAll = cat(2, XYZframeAll, str2num(tmpFileName)*ones(1,length(tmpLabelP(:))));
% % %             
% % %             
% % %         end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        if (j > keyframes(kfIndex))                    
            kfIndex = kfIndex + 1;                   
        end
        
        kfList = keyframes(kfIndex-1);        
        kfList = cat(2, kfList, keyframes(kfIndex));
        
        % for presentation only to show a toy-example
        kfList = [1, 81];
        
        for ikfList=1:length(kfList)
            
            tmpFileName = sprintf('%04d', kfList(ikfList));
            load([worldpc_dir 'rgb_' tmpFileName '.mat']);    
            XYZworld = XYZworld(:,validIndex);   
            XYZworldAll = cat(2, XYZworldAll, XYZworld); % concatenate into the existing world coordinates of the previous frames

            labelPpath = [label_dir tmpFileName '.mat'];%label of the key frame
            if (nLabel == 4)
                tmpLabelP = load(labelPpath, 'superLabel');
            elseif(nLabel == 13)
                tmpLabelP = load(labelPpath, 'mapLabel13');
                tmpLabelP.superLabel = tmpLabelP.mapLabel13;
                tmpLabelP.mapLabel13 = [];
            end
            tmpLabelP = tmpLabelP.superLabel;         
            tmpLabelP = tmpLabelP(y1:y2,x1:x2,:);
            % transfer the label from the the image space
            XYZlabelAll = cat(2, XYZlabelAll, tmpLabelP(:)');

            % frame no
            XYZframeAll = cat(2, XYZframeAll, str2num(tmpFileName)*ones(1,length(tmpLabelP(:))));        
        
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    end
    
    % RGB = RGB(:,validIndex);
    
    % load current frames's TRANSFORMATION MATRIX to project world
    % coordinates UPTO last frame into the current frame image space to infer some labels
    extrinsicIndex = str2num(filenameC);
    Rc2w = extrinsicsC2W(1:3,1:3, extrinsicIndex);
    Tc2w = extrinsicsC2W(1:3,4, extrinsicIndex);
    pts = bsxfun(@minus, Rc2w'*Tc2w, Rc2w'*XYZworldAll); % x=(Rc2w')*X-(Rc2w')*(Tc2w)
    pts = pts';    
    
    % project the labels back to the frame
    focal_length_x = K(1,1);
    focal_length_y = K(2,2);
    center      = [K(1,3) K(2,3)];
    projX       = [];
    projY       = [];   
    projIndices = [];    
    
    for jj=1:size(pts,1)
        projX(jj)=round((pts(jj,1)*focal_length_x)/pts(jj,3) + center(1)) - (x1-1);
        projY(jj)=round((pts(jj,2)*focal_length_y)/pts(jj,3) + center(2)) - (y1-1);        
    end    
    
%     tmpIndex = find((projX > 0 & projX <= size(labelP,2)) & (projY > 0 & projY <= size(labelP,1))); % CHANGE THE size(labelP,*) later on with parameter value
%     projIndices = cat(2, projIndices, tmpIndex');
%     
%     projX = projX(projIndices);
%     projY = projY(projIndices);    
%     projL = XYZlabelAll(projIndices);
%     projF = XYZframeAll(projIndices);
%     save('XYZworldAll.mat', 'XYZworldAll', 'XYZlabelAll', 'XYZframeAll');    
%     clear XYZworldAll XYZlabelAll pts XYZframeAll;
    
    vis = 0;    
%     if (vis)
%         
%         croppedRGB = rgbC;
%         f2 = figure; imagesc(croppedRGB); title(['projected from global point cloud' filenameC]);
%         position1 = get(f2, 'OuterPosition');
%         set(f2, 'OuterPosition', [10 position1(2:4)]);
%         hold on;
%         tmpIndex = find(projL == 1);
%         plot(projX(tmpIndex), projY(tmpIndex), '.c');        
%         tmpIndex = find(projL == 2);
%         plot(projX(tmpIndex), projY(tmpIndex), '.r');        
%         tmpIndex = find(projL == 3);
%         plot(projX(tmpIndex), projY(tmpIndex), '.g');        
%         tmpIndex = find(projL == 4);
%         plot(projX(tmpIndex), projY(tmpIndex), '.b');
%         %keyboard;
% 
%     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % pixel-wise unary data term based on 3D geometric projection
    
    pwDataTermG = zeros(r,c,nLabel+1); % default zero to give precedence over flow-based score on the regions where we have no projection
    
    for i= 1:spixelNumCur
        
        %find the superpixel of index i
        seg         = limCur==i;
        %xSeg2d = xc(seg); ySeg2d = yc(seg); %x-coordinate %y-coordinate            
        segIndex    = find(limCur == i);
        
        % take evidence from all the previous frames's projections (NOT JUST RANDOM FRAMES IN BETWEEN)
        singleFrameSize = r*c;       % 

%         if (0>=(j-geomUnaryWindowSize))
%             initFrame       = 1;         % start of the window
%             windowLen       = j - initFrame; % length of the window
%         else
%             
%             initFrame = ( j- geomUnaryWindowSize);
%             windowLen  = geomUnaryWindowSize;
%         end

        windowLen       = 2;        
        geomScores      = zeros(nLabel+1, windowLen);
        isProjected     = zeros(nLabel+1, windowLen); % Boolean flag to determine whether a label appears within a current projection

%        for jFrame=initFrame:windowLen       
        for jFrame=1:windowLen
        
            
            startOffset     = (jFrame-1)*singleFrameSize+1;
            endOffset        = startOffset+singleFrameSize-1;
            
            % get j-th frame pcl projection into the current image space
            curProjX        = projX(startOffset:endOffset);
            curProjY        = projY(startOffset:endOffset);
            curLabel        = XYZlabelAll(startOffset:endOffset);
            curFrame        = XYZframeAll(startOffset:endOffset);
            
%             if (~isempty(find(curFrame ~= (jFrame+initFrame-1))))                
%                 keyboard;
%                 display('Frame numbers are not same');
%             end
            
            % find the indices that fall within the range of the image
            tmpIndex        = find((curProjX > 0 & curProjX <= 560) & (curProjY > 0 & curProjY <= 425)); % CHANGE THE size(labelP,*) later on with parameter value
            %tmpIndex        = find((curProjX > 0 & curProjX <= size(labelP,2)) & (curProjY > 0 & curProjY <= size(labelP,1))); % CHANGE THE size(labelP,*) later on with parameter value
            projIndices     = tmpIndex';

            curProjX    = curProjX(projIndices);
            curProjY    = curProjY(projIndices);    
            curProjL    = curLabel(projIndices);
            curProjF    = curFrame(projIndices);
            
            % find the intersected projected pixels and current pixels within the
            % superpixels
            projIndex                         = sub2ind([r, c], curProjY, curProjX);            
            [cIndex, IsegIndex, IprojIndex]   = intersect(segIndex, projIndex);        
            xCoords     = curProjX(IprojIndex);
            yCoords     = curProjY(IprojIndex);
            labels      = curProjL(IprojIndex);
            frames      = curProjF(IprojIndex);
            % visualize the projected pixels in the current image
%             if (i == 30 | i == 34)
%                 keyboard;
%             end
            
%             if (str2num(filenameC) == 45 && i==13)
%                 keyboard;
%             end            
            
            if (vis)
                f3 = figure; imagesc(rgbC);
                %position3 = get(f3, 'OuterPosition');
                %set(f3, 'OuterPosition', [position1(3)+230 position3(2:4)]);
                hold on; plot(xCoords, yCoords, '+g');            
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
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    geomScores(ii+1, jFrame) = projWeight*curGeomScore;
                    
                    % more than 5 percent pixels are explained by a label is considered, others are considered as noise (since we are doing mean over multiple frames)
                    if (curGeomScore > 0.05) 
                        isProjected(ii+1, jFrame) = 1; % this label is present within the superpixel when projected from j-th frame
                    end
                    
                end

            end


        end
        
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
% % %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %         [cIndex, IsegIndex, IprojIndex]   = intersect(segIndex, projIndex);        
% % %         xCoords     = projX(IprojIndex);
% % %         yCoords     = projY(IprojIndex);
% % %         labels      = projL(IprojIndex);
% % %         frames      = projF(IprojIndex);
% % %         %if (i == 34)
% % %         %    keyboard;
% % %         %end
% % %         % visualize the projected pixels in the current image
% % %         if (vis)
% % %             f3 = figure; imagesc(rgbC);
% % %             position3 = get(f3, 'OuterPosition');
% % %             set(f3, 'OuterPosition', [position1(3)+230 position3(2:4)]);
% % %             hold on; plot(xCoords, yCoords, '+g');            
% % %             pause; close(f3);            
% % %         end
% % %         
% % %         for ii=0:4
% % %             % fraction of pixel inside the superpixel that can be explained by the label (ii+1). used as geometric unary scores per pixel
% % %             if (~isempty(find(labels == ii)))
% % %                 
% % %                 sizeWithLabelii = length(find(labels == ii));
% % %                 geomScore = sizeWithLabelii/length(labels);
% % %                 if (isnan(geomScore))
% % %                     keyboard;
% % %                 end
% % %                 curPwDataTermG          = pwDataTermG(:,:,ii+1);
% % %                 curPwDataTermG(seg)     = -geomScore; % more negative is better
% % %                 pwDataTermG(:,:,ii+1)   = curPwDataTermG;
% % %                         
% % %             end
% % %             
% % %         end
% % %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           
        
    end    
    
    clear labels seg segIndex;

%     save('XYZworldAll.mat', 'XYZworldAll', 'XYZlabelAll', 'XYZframeAll');    
    clear XYZworldAll XYZlabelAll pts XYZframeAll;

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
        
    if (~exist(save_dir_unary, 'dir'))
        mkdir(save_dir_unary);
    end
    
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
    
    display(['Graphcut running on frame ' filenameC]);
    tic; [gch, L] = GraphCut('expand',gch); toc;
    gch = GraphCut('close', gch);
    smoothedPredCp = L;
    if (0)
        %close(f1);        
        %f2 = figure;
        f1 = figure;
        position1 = get(f1, 'OuterPosition');
        clf(f1);
        subplot(1,3,1); imagesc(rgbC); title(['rgb-frame-' strName2]);
        %subplot(1,3,2); imagesc(labelP); title(['previous-label-' strName]);
        subplot(1,3,3); imagesc(smoothedPredCp); title(['propagated label-' strName2]);    
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
%     %write_data(pwDataTermC, [save_dir_unary  strName2 '_cu']);
%     writeDataTxt(pwDataTermC, [save_dir_unary  strName2 '_cu']);
%     save([save_dir_unary  strName2 '_uf.mat'], 'segCur'); % save the flow-based unary


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
    save([label_dir_pred strName2 '.mat'], 'smoothedPredCp');
    
    
end
