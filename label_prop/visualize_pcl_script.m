
% this script has been modified for Active Vision Dataset
% Md Alimoor Reza, mreza@masonlive.gmu.edu, January 2018
clear; clc;
video_names         = {'Home_001_1', 'Home_005_1', 'Home_002_1', 'Home_003_1'};
v_index             = 4;
video_name          = video_names{v_index};
src_dir             = '/home/reza/work/label_props/';
SELECT_ALL_FRAME    = 0;
SELECT_KEY_FRAME    = 1;
GENERATE_XYZworld   = 0;
VISUALIZE_XYZworld  = 0;
PRUNE_KEY_FRAME     = 0;

%CALIBRATED: fx,fy,cx,cy,k1,k2,p1,p2
% 1070, 1069.126, 927.269, 545.76, 0.035321, .0025428, .002387, -.00241
% COLMAP REESTIMATION
%HOME_001_1: 1920 1080 1049.51 1092.28 927.269 545.76 0.382444 0.105826 0.000859549 -0.00143275
%HOME_001_2: 1920 1080 1049.4  1100.11 927.269 545.76 0.38218 0.105974 0.000376765 -0.00133692
load(sprintf('%s/%s/intrinsic.mat', src_dir, video_name), 'K');

load(sprintf('%s/%s/image_structs.mat', src_dir, video_name), 'image_structs', 'scale');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read the content of the 'allframes' store them into a mat file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (SELECT_ALL_FRAME)
    
    %for iVideo=1:length(video_names)

        %video_name = video_names{iVideo};

        if (exist([src_dir video_name '/allframes.mat']))
            display([video_name ' allframes.mat exist']);
            %continue;
        end
        % allframes for label-propagation
        allframeDir = [src_dir video_name '/jpg_rgb/'];
        files = dir([allframeDir '*.jpg']);        
        allframes = cell(length(files),1);
        %extrinsicsW2C = zeros(3,4,length(files));
        extrinsicsC2W = zeros(3,4,length(files)); 
        noRt          = zeros(1,length(files)); 
        
        for iF=1:length(files)
            % frame name 
            fileName = files(iF).name;        
            number = fileName(1:end-6); % last two digits represents 01-RGB, 02-Depth, 03-Raw-depth, 04-Improved-depth
            allframes{iF} = number;
            
            % getting the extrinsics            
            idx = find(strcmp({image_structs(:).image_name}, fileName)==1);
            
            fprintf('%d) %s frame at index %d\n', iF, fileName, idx);
            
            Rw2c = image_structs(idx).R;
            Tw2c = image_structs(idx).t;
            if (~isempty(Rw2c))
                % scaling suggested by Prof Jana
                Rc2w = inv(Rw2c);
                Tc2w = -Rc2w*Tw2c*scale/1000;
                Transc2w = [Rc2w Tc2w];
                %extrinsicsW2C(:,:,iF) = T;
                extrinsicsC2W(:,:,iF) = Transc2w;
                fprintf('OK\n')                
            else                
                fprintf('Empty (R,t)\n')
                noRt(iF) = 1;
            end
            
        end
        
        save([src_dir video_name '/allframes-extrinsics.mat'], 'allframes', 'extrinsicsC2W', 'scale', 'noRt');
        clear allframes;
        
        
    %end

    
    
end

% keyboard;
if (SELECT_KEY_FRAME)
    
    files = dir(fullfile(src_dir, video_name, ['label_' video_name '/*.mat']));
    trainKeyframes = cell(length(files),1);        
    for iF=1:length(files)
        % frame name 
        fileName = files(iF).name;        
        number = fileName(1:end-6); % last two digits represents 01-RGB, 02-Depth, 03-Raw-depth, 04-Improved-depth
        trainKeyframes{iF} = number;

    end
    save([src_dir video_name '/allKeyframes.mat'], 'trainKeyframes');
    
end

% keyboard;
DEPTH_CUTOFF_THRESHOLD = 7; % there are some artifacts in the depth image (active vision dataset). 9m or more
if (GENERATE_XYZworld)
    load([src_dir video_name '/allframes-extrinsics.mat'], 'allframes', 'extrinsicsC2W', 'noRt');
    % generate XYZworld
    if ~exist([src_dir video_name '/worldpc'])
        mkdir([src_dir video_name '/worldpc']);
    end
    
    for iF=1:length(allframes)
        fileName = allframes{iF};

        % load depth
        %depthFileName = [src_dir video_name '/depth_filled/' fileName '03.png']; % 03-Raw-depth
        depthFileName = [src_dir video_name '/high_res_depth/' fileName '03.png']; % 03-Raw-depth
        image = imread([src_dir video_name '/jpg_rgb/' fileName '01.jpg']); % 01-rgb image
        depth = double(imread(depthFileName)); % convert into meters        
                
        worldpcFileName = [src_dir video_name '/worldpc/' fileName '01.mat'];        
        fprintf('%d.%s frame worldpc file ', iF, fileName);
        if (~exist(worldpcFileName))
            if (~noRt(iF))
                % scaled by the factor         (our approach)
                %depth = depth/1000;
                %depth = depth*scale;
                %-------------------------------       
                %depth=depth/scale;             (Phil's suggestion)
                %-------------------------------

                % suggested by Prof Jana
                depth = depth/1000;        
                XYZcamera = depth2XYZcamera(K, depth, DEPTH_CUTOFF_THRESHOLD);


                % pick the valid points with their color
                valid = logical(XYZcamera(:,:,4));  valid = valid(:)';
                
                % REZA: 02/03/2018 eliminate depth-artifact region
                
                XYZ = reshape(XYZcamera,[],4)';
                RGB = reshape(image,[],3)';
                XYZ = XYZ(1:3,valid);
                RGB = RGB(:,valid);        

        %         % transform to world coordinate
                Transc2w = extrinsicsC2W(:,:,iF);

        %         %--------------------------------------------------
        %         Transw2c = extrinsicsW2C(:,:,iF);
        %         Rw2c = Transw2c(1:3,1:3);
        %         Tw2c = Transw2c(1:3,4);

        %         % Prof. Jana suggested this scaling
        %         %R1 = inv(image_structs(2).R)
        %         %t1 = -R1*image_structs(2).t*scale/1000         
        %         Rc2w = inv(Rw2c);
        %         Tc2w = -Rc2w*Tw2c*scale/1000;
        %         Transc2w = [Rc2w Tc2w];


                XYZworld = transformPointCloud(XYZ, Transc2w); %XYZ is in milimeters      
                fprintf('saving\n');
                
            else            
                
                XYZworld = []; XYZcamera=[]; RGB = []; valid = [];
                
            end
            
            save(worldpcFileName, 'XYZworld', 'RGB', 'valid');
            clear 'XYZcamera' 'XYZworld' 'RGB' 'XYZ' 'valid';      
                        
        else
            fprintf('exist\n');                
            
        end
        

    end


end


% keyboard;
if (VISUALIZE_XYZworld)

    XYZobject = [];
    RGBobject = [];
    %f1 = figure;
    load([src_dir video_name '/allframes-extrinsics.mat'], 'allframes', 'extrinsicsW2C', 'scale', 'noRt');
    
    % generate XYZworld
    
            
    for iF=1:length(allframes)
        fileName = allframes{iF};
        worldpcFileName = [src_dir video_name '/worldpc/' fileName '01.mat'];
        fprintf('%d.%s frame worldpc file loading \n', iF, fileName);
        if exist(worldpcFileName)
                load(worldpcFileName, 'XYZworld', 'RGB');

                if (~isempty('XYZworld'))
                    XYZobject = [XYZobject XYZworld];
                    RGBobject = [RGBobject RGB];

                    visualizePointCloud_av(XYZobject,RGBobject, 500);
                    pause;
                    clear XYZworld RGB;
                    close;                
                    
                end
        end
    end 
    
end


% keyboard;
if (PRUNE_KEY_FRAME) % some frames doesn't have R,t (Frustrating :( )
    
    load([src_dir video_name '/allframes-extrinsics.mat'], 'allframes', 'noRt');
    noRtFrames = {};
    idx = find(noRt == 1);
    for iF=1:length(idx)
        noRtFrames = cat(2, noRtFrames, allframes{idx(iF)});
    end
    load([src_dir video_name '/allKeyframes.mat'], 'trainKeyframes');
    
    % common frames which doesn't have (R,t)
    intersect(trainKeyframes, noRtFrames)' % I prefer it to be empty
    
    
    
end


