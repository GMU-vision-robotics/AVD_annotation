% labelObjectsScript
close all; clear;
startnum = 28;
fix_mode = 0;
% imdir = '/home/reza/Downloads/huhe_semantic_labels/farsight/annotation/train/img/';
% ext = '.png';
% outdir = 'annot';
% outext = '_objects.mat';

%% experiment to see if the propagation works on active_vision_dataset
% imdir = '/home/reza/work/annotation_hoiem/active_vision_dataset/';
% ext = '.jpg';
% outdir = 'annot_active_vision_';
% outext = '_labels.mat';

%% Home_001_1 (active vision dataset)

%% Home_005_1
% imdir = '/home/reza/work/label_props/Home_005_1/selected_images';
% outdir = '/home/reza/work/label_props/Home_005_1/annotated_selected_images';

%% Home_002_1
% imdir = '/home/reza/work/label_props/Home_002_1/selected_images/';
% outdir = '/home/reza/work/label_props/Home_002_1/annotated_selected_images/';

%% Home_003_1
imdir = '/home/reza/work/label_props/Home_003_1/selected_images/';
outdir = '/home/reza/work/label_props/Home_003_1/annotated_selected_images/';


ext = '.jpg';
outext = '_labels.mat';

files = dir(fullfile(imdir, ['*' ext]));
fn = {files.name};

if ~exist(outdir, 'file')
    disp(['creating ' outdir])
    try 
        mkdir(outdir);
    catch
        disp(['could not create ' outdir]);
    end
end

for k = startnum:numel(fn)

    im = im2double(imread(fullfile(imdir, fn{k})));
    outname = fullfile(outdir, [strtok(fn{k}, '.') outext]);
    
    % if objects already exist, only edit if in fix_mode
    if exist(outname, 'file')
        if fix_mode
            load(outname);
            disp(' ');
            disp([num2str(k) ': ' fn{k}]);
            objects = objectLabelingTool(im, objects, fn{k});
            save(outname, 'objects');
            pause;
        else
            display([num2str(k) '. :' outname ' exists']); 
            
        end
    else
        disp(' ');
        disp([num2str(k) ': ' fn{k}]);
        objects = objectLabelingTool(im); 
        save(outname, 'objects');
    end
end