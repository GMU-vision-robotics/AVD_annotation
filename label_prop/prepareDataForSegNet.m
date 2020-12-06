
clear; clc; close all;
nLabel = 13;
video_name = {'hotel_umd40', 'hv_c6', 'studyroom', 'mit_32'};
src_dir    = '/media/New Volume/label_prop/';
save_dir = ['/home/reza/Downloads/SegNet/SUN/'];

file = fopen('train.txt', 'w');
k = 0;

sW = 480; sH = 360;

for vi=1:length(video_name)
    
    rgb_dir     = [src_dir video_name{vi} '/RGB/'];
    load([video_name{vi} '/keyframes.mat'], 'keyframes');
    for iFiles=1:length(keyframes)
        frameNo = sprintf('%04d',keyframes(iFiles));
        fileName = [src_dir video_name{vi} '/label/' frameNo '.mat'];   
        if (nLabel == 4)
            load(fileName, 'superLabel');
            labels = unique(superLabel(:));
            gtLabel = superLabel;
            clear superLabel;
        else
            load(fileName, 'mapLabel13');
            labels = unique(mapLabel13(:));
            gtLabel = mapLabel13;
            clear mapLabel13;
        end                    
        labels(find(labels==0)) = []; % delete zero
        if (isempty(labels))
            display([video_name{vi} ': ' frameNo ' shouldn''t be empty labeled']);
            keyboard;
        end
           
        saveName = [video_name{vi} '_' frameNo '.png'];
        rgbImg = imread([rgb_dir '/rgb_' frameNo '.png']);
        
        if (0)
           figure; subplot(1,2,1); imagesc(gtLabel); title(saveName);           
           subplot(1,2,2); imagesc(rgbImg); title(saveName);           
           pause;close;         
        end

        % save it
        rgbImg = imresize(rgbImg, [sH sW]);
        gtLabel = uint8(imresize(gtLabel, [sH sW], 'nearest'));        
        
        imwrite(rgbImg, [save_dir '/train/' saveName]);
        imwrite(gtLabel , [save_dir '/trainannot/' saveName]);
        
        fprintf(file, '%s %s\n', ['/tmp/mreza/SegNet/SUN/train/' saveName], ['/tmp/mreza/SegNet/SUN/trainannot/' saveName]);
        clear gtLabel;
        display([num2str(k) '. done processing ' saveName]);
        k = k + 1;
        
    end
    clear keyframes;
end

fclose(file);