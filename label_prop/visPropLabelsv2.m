
addpath(genpath('./export_fig/'));
clear; close all;

vis = 1;
colors =    [ 0.6 0.0 0.0;            % 0)
              0.0 0.0 0.0;            % 1)
              0.7 0.0 0.0;            % 2) 
              0.0 0.0 0.5;            % 3) 
              0.0 0.0 0.0;            % 4) 
              0.2 0.2 0.2;            % 5) 
              0.0 0.0 0.0;            % 6) 
              0.2 1.2 0.2;            % 7) 
              0.0 0.0 0.0;            % 8) 
              0.0 0.0 0.0;            % 9) 
              0.4 0.4 0.4;            % 10) 
              0.0 0.0 1.0;            % 11) 
              1.0 0.7 0.4;            % 12) 
              0.0 0.0 0.0;            % 13) 
              0.6 1.0 1.0;            % 14) 
              0.0 1.0 1.0;            % 15) 
              1.0 0.6 0.6;            % 16) 
              1.0 0.0 0.0;            % 17) 
              0.0 0.0 0.0;            % 18) 
              0.7 0.7 0.0;            % 19) 
              1.0 0.4 0.7;            % 20) 
              0.0 0.0 0.0;            % 21) 
              0.0 0.0 0.0;            % 22) 
              0.0 0.0 0.0;            % 23) 
              0.6 0.8 1.0;            % 24) 
              1.0 0.6 0.7;            % 25) 
              0.0 0.0 0.0;            % 26) 
              0.0 0.0 0.0;            % 27) 
              0.9 0.0 0.0;            % 28) 
              0.0 0.0 0.0;            % 29) 
              0.0 0.0 0.0;            % 30) 
              0.0 0.0 0.0;            % 31) 
              0.0 0.6 0.0;            % 32)
              
              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              0.0 0.9 0.3;            % 33) 
              0.0 0.7 0.0;            % 34) 
              0.5 1.0 0.5;            % 35) 
              0.0 0.7 0.7;            % 36) 
              0.0 0.0 7.0;            % 37) 
              1.0 1.0 0.7;            % 38) 
              0.9 0.0 0.9;            % 39) 
              0.0 0.5 1.0;            % 40) 
              1.0 0.3 0.3;            % 41) 
              0.7 0.0 0.0;            % 42) 
              0.9 0.9 0.0;            % 43) 
              1.0 0.7 1.0;            % 44) 
              0.9 1.0 1.0;            % 45) 
              0.5 0.5 0.0;            % 46) 
              0.5 0.5 0.5;            % 47) 
              0.0 0.0 0.4;            % 48) 
              0.7 0.7 0.7;            % 49) 
              0.3 0.0 0.0;            % 50) 
              0.0 0.3 0.0;            % 51)

          

              0.0 0.9 0.3;            % 52) 
              0.0 0.7 0.0;            % 53) 
              0.5 1.0 0.5;            % 54) 
              0.0 0.7 0.7;            % 55) 
              0.0 0.0 7.0;            % 56) 
              1.0 1.0 0.7;            % 57) 
              0.9 0.0 0.9;            % 58) 
              0.0 0.5 1.0;            % 59) 
              1.0 0.3 0.3;            % 60) 
              0.7 0.0 0.0;            % 61) 
              0.9 0.9 0.0;            % 62) 
              1.0 0.7 1.0;            % 63) 
              0.9 1.0 1.0;            % 64) 
              0.5 0.5 0.0;            % 65) 
              0.5 0.5 0.5;            % 66) 
              0.0 0.0 0.4;            % 67) 
              0.7 0.7 0.7;            % 68) 
              0.3 0.0 0.0;            % 69) 
              0.0 0.3 0.0;            % 70)

              0.0 0.9 0.3;            % 71) 
              0.0 0.7 0.0;            % 72) 
              0.5 1.0 0.5;            % 73) 
              0.0 0.7 0.7;            % 74)  
              0.0 0.0 7.0;            % 75) 
              1.0 1.0 0.7;            % 76) 
              0.9 0.0 0.9;            % 77) 
              0.0 0.5 1.0;            % 78) 
              1.0 0.3 0.3;            % 79) 
              0.7 0.0 0.0;            % 80) 
              0.9 0.9 0.0;            % 81) 
              1.0 0.7 1.0;            % 82) 
              0.9 1.0 1.0;            % 83) 
              0.3 0.0 0.0;            % 84) furniture-others
              0.0 0.3 0.0;];          % 85) object-others
              
%video_names = {'hotel_umd40'};
% video_names = {'studyroom'};
%video_names = {'mit_32'};
%video_names = {'hv_c5'};
%video_names   = {'Home_001_1', 'Home_005_1', 'Home_002_1', 'Home_003_1', 'Home_004_1',};
video_names   = { 'Home_006_1', 'Home_007_1', ...
    'Home_010_1', 'Home_011_1', 'Home_016_1'};

srcDir = '/home/yimeng/AVD_annotation-master/label_prop/';
rgbExtension         = '01';
depthExtension       = '03';
superpixelExtension  = '03';
labelExtension       = '01';
worldpclExtension    = '01';

rgbFileType         = '.jpg';
depthFileType       = '.png';
superpixelFileType  = '.mat';
labelFileType       = '.mat';
worldpclFileType    = '.mat';

IS_CROPPED = 1;
start_cx = 160; finish_cx = 1660;
%figure_path = 'figure';



for iVideo=1:length(video_names)
    
    video_name = video_names{iVideo};    

    if (~exist('predDirName', 'var'))
        predDirName = 'label_pred_geom_only_85_with_smoothness_0.5';
    end

    if (~exist('gtDirName', 'var'))
        %gtDirName = sprintf('label_%s',video_name);
        gtDirName = 'final_label';
    end

    if (~exist('rgbDirName', 'var'))
        rgbDirName = 'jpg_rgb';    
    end
    
    gtPath      = [srcDir '/' video_name '/' gtDirName ];  
    predPath    = [srcDir '/' video_name '/' predDirName ]; 
    rgbPath     = [srcDir '/' video_name '/' rgbDirName];
    load([srcDir video_name '/allframes-extrinsics.mat'], 'allframes', 'noRt');
    load([srcDir video_name '/allKeyframes.mat'], 'trainKeyframes');

    f1 = fopen([srcDir '/' video_name '/input.txt' ], 'w');
    if (IS_CROPPED)
        if (~exist([predPath '/figure_cropped'], 'dir'))
            mkdir([predPath '/figure_cropped']);
        end
        figure_path = 'figure_cropped';
    else
        if (~exist([predPath '/figure'], 'dir'))
            mkdir([predPath '/figure']);
        end
        figure_path = 'figure';
        
    end
    
    for iFrames=1:length(allframes)
        
        curFrame = allframes{iFrames};
        fprintf('%d). processing %s \n', iFrames, curFrame);
        if (noRt(iFrames) == 1)
            fprintf('%s has no (R,t)\n',curFrame);
            continue;
        end
        
        iskeyframe = find(strcmp(trainKeyframes,curFrame) == 1);
        if ~isempty(iskeyframe)
            load([gtPath   '/' curFrame labelExtension labelFileType], 'mapLabel');
            annot = mapLabel;
            annot = annot + 1;        
            clear mapLabel;
            outname = '_annot_label.png';
        else
            if ~exist([predPath   '/' curFrame labelExtension labelFileType])
                disp([predPath   '/' curFrame labelExtension labelFileType ': NOT GENERATED skipping ..']);
                continue;
            end
            
            load([predPath   '/' curFrame labelExtension labelFileType], 'smoothedPredCp');
            annot = smoothedPredCp;
            clear smoothedPredCp;
            outname = '_prop_label.png';
        end

        if (exist(fullfile(predPath, figure_path, [curFrame outname])))
           fprintf('%s exists\n',fullfile(predPath, figure_path, [curFrame outname])) 
           continue;
        end
        
        fprintf(f1, '%s\n', [curFrame outname]);

        % manual inspection of the labels
        %%
%         img = imread([rgbPath '/' curFrame rgbExtension rgbFileType]);
%         f2 = figure; imagesc(img); position1 = get(f2, 'OuterPosition');
%         set(f2, 'OuterPosition', [10 position1(2:4)]);title([num2str(iFrames) ': ' curFrame]);
%         f3 = figure; imagesc(annot); position2 = get(f3, 'OuterPosition');
%         set(f3, 'OuterPosition', [position1(3)+230 position2(2:4)]);
%         pause;
%         close all;
        %%
        
        if (vis)
            
            img = imread([rgbPath '/' curFrame rgbExtension rgbFileType]);
            grayim = double(repmat(rgb2gray(img), [1 1 3]));            
            %labim = label2rgb(labels); % random r,g,b color for the labels locations
            labelIds    = unique(annot(:));
            labelim     = uint8(zeros(size(annot,1)*size(annot,2), 3));
            for ilabelIds=1:length(labelIds)
                idx = find(annot == labelIds(ilabelIds));
                uint8(255*colors(labelIds(ilabelIds),:));
                labelim(idx,:) = repmat( uint8(255*colors(labelIds(ilabelIds),:)), length(idx),1);
            end
            labelim = reshape(labelim, [size(annot,1) size(annot,2) 3]);
            
%            figure; imagesc(labelim); title(curFrame);   
            if (IS_CROPPED)
               labelim = labelim(:,start_cx: finish_cx,:); 
            end
            
            %f = figure; imagesc(labelim); axis off; set(f, 'visible', 'on');
            %[a,b] = export_fig(f);
            %a = imresize(a, [size(labelim,1) size(labelim,2)], 'nearest');
            %imwrite(a, fullfile(predPath, figure_path, [curFrame outname]));            
            
            f = figure; set(f, 'Visible', 'off');
            imagesc(labelim);
            set(gca,'units','pixels');
            set(gca,'units','normalized','position',[0 0 1 1]);
            axis off;
            axis tight;saveas(f, fullfile(predPath, figure_path, [curFrame outname]));
            %set(f, 'visible', 'on');

            %imgFromFrame = im2frame(zbuffer_cdata(f));
            %a = imresize(imgFromFrame.cdata, [size(labelim,1) size(labelim,2)], 'nearest');
            %imwrite(a, fullfile(predPath, figure_path, [curFrame outname]));  
            %pause; 
            pause(0.8); close;
            
            clear labelim a grayim;
            %pause(0.5);
            
            
%             [h,s,v] = rgb2hsv(labelim);
%             v = v*0.5 + grayim(:, :, 1)*0.5;
%             figure; imagesc(hsv2rgb(h,s,v)); title(curFrame);            
%             keyboard;
        end
        
    end
    fclose(f1);
    
end

% tmpim = im;
% ind = repmat(objects.labels>0, [1 1 3]);
% tmpim(ind) = grayim(ind)*0.67 + 0.33;
% 
% % red edges
% ind = repmat(objects.bnd, [1 1 3]);
% vals = cat(3, objects.bnd, false(size(objects.bnd)), false(size(objects.bnd)));
% 
% tmpim(ind) = vals(ind);
% 
% hold off, imagesc(tmpim), axis image



% labels; % predicted label
% labim = label2rgb(labels); % random r,g,b color for the labels locations
% [h,s,v] = rgb2hsv(labim);
% v = v*0.5 + grayim(:, :, 1)*0.5;
% hold off, imagesc(hsv2rgb(h,s,v));
