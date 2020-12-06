clear; clc; close all;
objectNameToNumberMap = create_global_object_mapping();
root_dir = '/home/yimeng/AVD_annotation-master';
imdir    = { [root_dir '/Home_001_1/selected_images/'], ...
             [root_dir '/Home_005_1/selected_images/'], ...
             [root_dir '/Home_002_1/selected_images/'], ...
             [root_dir '/Home_003_1/selected_images/'], ...
             [root_dir '/Home_011_1/selected_images/'], ...
             [root_dir '/Home_006_1/selected_images/'], ...
             [root_dir '/Home_010_1/selected_images/'], ...
             [root_dir '/Home_004_1/selected_images/'], ...
             [root_dir '/Home_016_1/selected_images/'], ...
             [root_dir '/Home_007_1/selected_images/'], ...
             [root_dir '/Home_014_1/selected_images/'], ...
             [root_dir '/Home_014_2/selected_images/'], ...
          };
      
indir  = {[root_dir '/Home_001_1/annotated_selected_images/'], ...
          [root_dir '/Home_005_1/annotated_selected_images/'], ...
          [root_dir '/Home_002_1/annotated_selected_images/'], ...
          [root_dir '/Home_003_1/annotated_selected_images/'], ...
          [root_dir '/Home_011_1/annotated_selected_images/'], ...
          [root_dir '/Home_006_1/annotated_selected_images/'], ...
          [root_dir '/Home_010_1/annotated_selected_images/'], ...
          [root_dir '/Home_004_1/annotated_selected_images/'], ...
          [root_dir '/Home_016_1/annotated_selected_images/'], ...
          [root_dir '/Home_007_1/annotated_selected_images/'], ...
          [root_dir '/Home_014_1/annotated_selected_images/'], ...
          [root_dir '/Home_014_2/annotated_selected_images/'], ...
          };
outdir = {[root_dir '/Home_001_1/final_label'], ...
          [root_dir '/Home_005_1/final_label'], ...
          [root_dir '/Home_002_1/final_label'], ...
          [root_dir '/Home_003_1/final_label'], ...
          [root_dir '/Home_011_1/final_label'], ...
          [root_dir '/Home_006_1/final_label'], ...
          [root_dir '/Home_010_1/final_label'], ...
          [root_dir '/Home_004_1/final_label'], ...
          [root_dir '/Home_016_1/final_label'], ...
          [root_dir '/Home_007_1/final_label'], ...
          [root_dir '/Home_014_1/final_label'], ...
          [root_dir '/Home_014_2/final_label'], ...
          };
ext    = '.jpg';
intext = '_labels.mat';
outext = '.mat';
video_index = 12;
startnum = 1;
files = dir(fullfile(imdir{video_index}, ['*' ext]));
fn    = {files.name};

if ~exist(indir{video_index}, 'dir')
    error(['could not find intial annotated mat at: ' indir{video_index}]);    
end

for k = startnum:numel(fn)

    im = im2double(imread(fullfile(imdir{video_index}, fn{k})));
    inname = fullfile(indir{video_index}, [strtok(fn{k}, '.') intext]);    
    load(inname, 'objects'); % cell-structure
    disp(' ');
    disp([num2str(k) ': ' fn{k}]);
    
    % relabel using the mapping
    outname = fullfile(outdir{video_index}, [strtok(fn{k}, '.') outext]);
    if ~exist(outname)
        [r, c, ~] = size(im);
        mapLabel = zeros(r,c);

        display([num2str(k) ')Now relabeling: ' outname]);           
        for iobj=1:length(objects.name)
           %idx = find(objects.rawmask{iobj}); % find all the pixel from the raw mask and then relabel with number from objectNameToNumber Map
           idx = find(objects.labels == iobj); 
           
           %if strcmp(objects.name{iobj}, 'cup')
           %    objects.name{iobj} = 'objects-other';
           %end
           
           labelExists = find(strcmp(objectNameToNumberMap.keys, objects.name{iobj}) == 1);
           if (~isempty(labelExists))
               display(['relabeling ' objects.name{iobj}]);
               mapLabel(idx) = objectNameToNumberMap(objects.name{iobj});
           else           
               display(['Wrong name: ' objects.name{iobj}]);           
               error(['Wrong name: ' objects.name{iobj}]);           
           end

        end
        
        vis = 0;
        if (vis)
            figure; imagesc(im);
            figure; imagesc(mapLabel);
            pause; close all;        
        end
        if ~exist(outdir{video_index})
            mkdir(outdir{video_index});
        end
        save(outname, 'mapLabel');
        
    
    else
        display(['Already relabeled: ' outname]);           
        
    end
end





%% fixing annotation inconsistent segments
% Home_001_1
%%%%%%%%%%%%%%%%
%1
%%%
% cc = bwconncomp(objects.rawmask{4}); % nature_valley_sweet_and_salt was annotated as toaster

%2. ('annot_Home_001_1/000110000030101_labels.mat')
%%%
% srcId = 4; % toaster
% destId = 6; % oven
% oven_rm = objects.rawmask{destId};
% toaster_rm = objects.rawmask{srcId};
% cc = bwconncomp(toaster_rm); % one of the oven was annotated as toaster
% oven_rm(cc.PixelIdxList{1}) = 1;
% toaster_rm(cc.PixelIdxList{1}) = 0;
% figure; imagesc(oven_rm)
% figure; imagesc(toaster_rm);
% objects.rawmask{destId} = oven_rm;
% objects.rawmask{srcId} = toaster_rm;

% objects.labels(cc.PixelIdxList{1}) = destId;
% save(inname, 'objects');


% 3. label_Home_001_1/000110001080101.mat
%%%
%objects.name{4} = 'unknown'; % from 'papar'


% 4. label_Home_001_1/000110002910101.mat
% srcId = 4; % toaster
% destId = 6; % oven
% oven_rm = objects.rawmask{destId};
% toaster_rm = objects.rawmask{srcId};
% cc = bwconncomp(toaster_rm); % one of the oven was annotated as toaster
% oven_rm(cc.PixelIdxList{1}) = 1;
% toaster_rm(cc.PixelIdxList{1}) = 0;
% figure; imagesc(oven_rm)
% figure; imagesc(toaster_rm);
% objects.rawmask{destId} = oven_rm;
% objects.rawmask{srcId} = toaster_rm;
% objects.labels(cc.PixelIdxList{1}) = destId;
% save(inname, 'objects');

% 5. 000110002910101.mat
% objects.name{13} = 'unknown'; % from 'objectLabelingScript' 

% 6. 000110012480101_labels.mat'  % 'remote' overriden by 'couch'
%%%
% couch_rm = objects.rawmask{4};
% remote_rm = objects.rawmask{5};
% objects.name{4} = 'remote';
% objects.name{5} = 'couch';
% objects.rawmask{4} = remote_rm;
% objects.rawmask{5} = couch_rm;
% figure; imagesc(objects.rawmask{4})
% figure; imagesc(objects.rawmask{5})
% idx = find(objects.rawmask{5}==1);
% objects.labels(idx) = 5;
% idx = find(objects.rawmask{4}==1);
% objects.labels(idx) = 4;
% save(inname, 'objects');
