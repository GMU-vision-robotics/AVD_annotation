function [gacc, perclassacc, iouacc, conf_mat, iou, cf] = evaluate_labelprop(video_names, srcDir, predDirName, gtDirName)
% if you use another test/train set change number of classes and the
% unlabeled index as well as number of iterations (needs to be equal to the test set size)

% gtPath = '/home/reza/Downloads/SegNet/SUN/testannot/'; % path to your ground truth images
% predPath = '/home/reza/Downloads/SegNet/SUN/testsave/'; %path to your predictions (you get them after you implement saving images in the test_segmentation_camvid.py script - or you write your own)
% gtPath = '/home/arsalan/work/SegNet/SUNGT_SUNPropv2/testannot/'; % path to your ground truth images
% predPath = '/home/arsalan/work/SegNet/SUNGT_SUNPropv2/testsave/'; %path to your predictions (you get them after you implement saving images in the test_segmentation_camvid.py script - or you write your own)

if (~exist('predDirName', 'var'))
    predDirName = 'label_pred_geom_only_10_with_smoothness_2.5';
end

if (~exist('gtDirName', 'var'))
    gtDirName = 'label10';    
end

if (~exist('rgbDirName', 'var'))
    rgbDirName = 'RGB';    
end


x1 = 41; x2 = 600;
y1 = 46; y2 = 470;

vis = 1;

color = [0 0 0 ;%unknown
        0 0 255 ;%bed
        0 0 120 ;%ceil
        0 75 0 ;%chair
        255 0 0 ; %floor
        0 204 204 ;%furn
        102 0 255 ;%#obj
        153 255 204 % painting
        0 255 0 ;%#table        
        255 128 0 ;%wall
        192 192 192 ;%#window        
        ];

for iVideo=1:length(video_names)    
    
    video_name = video_names{iVideo};
    
    gtPath      = [srcDir '/' video_name '/' gtDirName ];
    predPath    = [srcDir '/' video_name '/' predDirName];
    predVisDir = [srcDir '/' video_name '/' predDirName '/vis/'];

    clear valKeyframes;
    load([srcDir video_name '/train+valKeyframes.mat'], 'valKeyframes');

    groundTruths = {};
    skip = 0; % 2 first two are '.' and '..' so skip them
    predictions = {};
    
    for iFrames=1:length(valKeyframes)        
        groundTruths = cat(2, groundTruths, [gtPath   '/' sprintf('%04d', valKeyframes(iFrames)) '.mat']);
        predictions  = cat(2, predictions,  [predPath '/' sprintf('%04d', valKeyframes(iFrames)) '.mat']);
        
    end

    numClasses = 11;
    unknown_class = 1;

    totalpoints = 0;
    totalFrames = length(valKeyframes);
    cf = zeros(totalFrames,numClasses,numClasses);
    globalacc = 0;

    for i = 1:totalFrames
        display(num2str(i));

        %load(strcat(predPath, '/', predictions{i + skip}), 'ind'); % set this to iterate through your segnet prediction images        
        %pred = ind + 1; % i added this cause i labeled my classes from 0 to 11
        %clear ind;
    
        load(predictions{i}, 'smoothedPredCp');
        pred = smoothedPredCp;
        %pred = pred -1; % saved by adding one to each entries, but in ground truth has annotation from 0-10
        clear smoothedPredCp;
        
    %     pred = imread(strcat(predPath, '/', predictions(i + skip).name)); % set this to iterate through your segnet prediction images
    %     pred = pred + 1; % i added this cause i labeled my classes from 0 to 11

%         annot = imread(strcat(gtPath, '/', groundTruths(i + skip).name)); % set this to iterate through your ground truth annotations
%         annot = annot + 1; % i added this cause i labeled my classes from 0 to 11 -> so in that case the next line will find every pixel labeled with unknown_class=12

        load(groundTruths{i}, 'mapLabel10');
        annot = mapLabel10;
        annot = annot + 1;
        
        annot = annot(y1:y2, x1:x2);
        
        clear mapLabel10;
        
        if (vis)
            
            img = imread([srcDir '/' video_name '/' rgbDirName '/rgb_' sprintf('%04d', valKeyframes(i)) '.png']);
            cropImg = [];
            cropImg = cat(3, cropImg, img(y1:y2, x1:x2,1));
            cropImg = cat(3, cropImg, img(y1:y2, x1:x2,2));
            cropImg = cat(3, cropImg, img(y1:y2, x1:x2,3));
            
            % pred image
            predIds = unique(pred(:));
            predImg = zeros(size(annot,1)*size(annot,1),3);
            for iPredIds=1:length(predIds)
                idx = find(pred == predIds(iPredIds));
                predImg(idx,:) = repmat(color(predIds(iPredIds),:), length(idx),1);
            end
            predImg = reshape(predImg, [size(annot,1) size(annot,2) 3]);
            
            % ground truth image
            gtIds = unique(annot(:));
            gtImg = zeros(size(annot,1)*size(annot,1),3);
            for iGtIds=1:length(gtIds)
                idx = find(annot == gtIds(iGtIds));
                gtImg(idx,:) = repmat(color(gtIds(iGtIds),:), length(idx),1);
            end
            gtImg = reshape(gtImg, [size(annot,1) size(annot,2) 3]);
            
%             if (valKeyframes(i) == 1776)
%                 keyboard;
%             end
            f1 = figure; hold on; set(f1, 'visible', 'off');
            subplot(1,3,1); imagesc(cropImg); %title(sprintf('rgb: %04d', valKeyframes(i)));
            subplot(1,3,2); imagesc(uint8(gtImg)); %title(sprintf('gt: %04d', valKeyframes(i))); 
            subplot(1,3,3); imagesc(uint8(predImg)); %title(sprintf('propagated: %04d', valKeyframes(i))); 
            %keyboard;
            %pause;
            
            %set(f1,'position',[0 0 1 1],'units','normalized');
            if (~exist(predVisDir))
                mkdir(predVisDir);
            end
            img_ = im2frame(zbuffer_cdata(f1));
            im_save_as = [predVisDir '/' sprintf('prop_%04d', valKeyframes(i)) '.png'];
            imwrite(img_.cdata, [im_save_as]);    
            close;    

        
        end
        
        pixels_ignore = annot == unknown_class;
        pred(pixels_ignore) = 0;
        annot(pixels_ignore) = 0;

        totalpoints = totalpoints + sum(annot(:)> 1); % if want to ignore the background class
%         totalpoints = totalpoints + sum(annot(:)>-1); % otherwise consider everything

        % global and class accuracy computation
        for j = 1:numClasses
            for k = 1:numClasses
                    c1  = annot == j;
                    c1p = pred == k;
                    index = gather(c1 .* c1p);              
                    cf(i,j,k) = cf(i,j,k) + sum(index(:));
            end
                c1  = annot == j;
                c1p = pred == j;
                index = gather(c1 .* c1p);
                globalacc = globalacc + sum(index(:));

        end
    end

    cf = sum(cf,1);
    cf = squeeze(cf);

    % Compute confusion matrix
    conf = zeros(numClasses);
    for i = 1:numClasses
        if i ~= unknown_class && sum(cf(i,:)) > 0
            conf(i,:) = cf(i,:)/sum(cf(i,:));
        end
    end
    globalacc = sum(globalacc)/sum(totalpoints);

    % Compute intersection over union for each class and its mean
    intoverunion = zeros(numClasses,1);
    for i = 1:numClasses
        if i ~= unknown_class   && sum(conf(i,:)) > 0
            intoverunion(i) = (cf(i,i))/(sum(cf(i,:))+sum(cf(:,i))-cf(i,i));
        end
    end

    gacc = globalacc;
    perclassacc = sum(diag(conf))/(numClasses);
    iouacc = sum(intoverunion)/(numClasses);
    conf_mat = conf;
    iou     = intoverunion;
    display([' Global acc = ' num2str(globalacc) ' Class average acc = ' num2str(sum(diag(conf))/(numClasses)) ' Mean Int over Union = ' num2str(sum(intoverunion)/(numClasses))]);
    
    save([predVisDir '/' video_name '_performance.mat'], 'gacc', 'perclassacc', 'iouacc', 'conf_mat', 'iou');
end