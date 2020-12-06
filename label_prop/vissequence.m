function handle = vissequence(sequenceName)
% savePath = '/home/shared/work/NAS/SUN3D_preprocessing/';
% obj2str = get_object_to_structure_class_map();
if (~exist('sequenceName', 'var'))
    sequenceName = 'hotel_umd/maryland_hotel3';
end
vis = 0; % 0 for matlab pcl vis; 1 for frame vis; 2 for pcd file creation from matlab
if (~vis); handle = figure; else handle = 0; end;
if (vis == 2 || vis == 3)
    pclRGB = [];
    pclSLabel = [];
end

%figure; hold on;
% colorCode = [255 0 0;   
%              0 255 0;   % structure
%              0 0 255;   % furniture
%              0 255 255; % prop
%              50 50 50]; % others
        
color = [0 0 0;     % others
        0 255 255;  % floor
        255 0 0;    % structure
        0 255 0;    % furniture
        0 0 255];   % prop
    
% consts.FLOOR = 1;
% consts.STRUCTURE = 2;
% consts.FURNITURE = 3;
% consts.PROP = 4;         
dirList = dir([sequenceName '/*.mat']);
for cnt=1:length(dirList)
    
    matFileName = [sequenceName '/' dirList(cnt).name];
    %matFileName = [sequenceName '/' sprintf('%04d',cnt) '.mat'];
    
    if (exist(matFileName, 'file'))
        
        load(matFileName, 'image', 'depth', 'label', 'imgOverlaid', 'superLabel', 'RGB', 'XYZworld', 'valid');              
        SLabel = zeros(3, length(valid));        %3 x #Pixels matrix containing the color-coded super categories
        % for background pixels
        idx = find(superLabel == 0)';
        if (~isempty(idx))
            SLabel(:,idx) = repmat(colorCode(5,:)', 1, length(idx));
        end
        % for 4 category pixels        
        for iLabel=1:4
            idx = find(superLabel == iLabel)';
            if (~isempty(idx))
                SLabel(:,idx) = repmat(colorCode(iLabel,:)', 1, length(idx));
            end
        end        
        % retain only the valid ones
        SLabel = SLabel(:,valid);        
        
        % show only those frame where there is annotation
        isUnlabeled = isempty(find(label(:) ~= 0));
        if (~isUnlabeled)                        
            if (vis == 1)                
                f1 = figure; position1 = get(f1, 'OuterPosition'); imagesc(imgOverlaid); ...
                    set(f1, 'OuterPosition', [10 position1(2:4)]);title([sequenceName ': ' num2str(cnt)]);
                f2 = figure; position2 = get(f2, 'OuterPosition'); imagesc(superLabel); ...
                    set(f2, 'OuterPosition', [position1(3)+230 position2(2:4)]); title(['superclass labels: ' num2str(cnt)]);     
                %pause;
                if (~exist([sequenceName '/rgb_debug/']))
                    mkdir([sequenceName '/rgb_debug/']);
                end                
                img_ = im2frame(zbuffer_cdata(f1));
                imwrite(img_.cdata, [sequenceName '/rgb_debug/' dirList(cnt).name(1:end-4) '_rgb.png']);
                img_ = im2frame(zbuffer_cdata(f2));
                imwrite(img_.cdata, [sequenceName '/rgb_debug/' dirList(cnt).name(1:end-4) '_superclass.png']);
                pause(1);
                close all;
                
            elseif (vis == 2) % create pcl file. it is useful for rotating large point-cloud file which is otherwise slow and clumsy in matlab.
                curPcl = [XYZworld; double(RGB)/255]; % x y z r g b
                pclRGB = [pclRGB curPcl];
                                
                curPcl = [XYZworld; double(SLabel)/255]; % x y z r g b
                pclSLabel = [pclSLabel curPcl];
                if (mod(cnt,5) == 0)
                    fprintf('loaded frame %d of %d\n', cnt, length(dirList));
                end
                
            elseif (vis == 3) % create txt file which will be later used to convert to .vtk file. it is useful for rotating large point-cloud file which is otherwise slow and clumsy in matlab.
                curPcl = [XYZworld; double(RGB)]; % x y z r g b
                pclRGB = [pclRGB curPcl];
                                
                curPcl = [XYZworld; double(SLabel)]; % x y z r g b
                pclSLabel = [pclSLabel curPcl];
                if (mod(cnt,5) == 0)
                    fprintf('loaded frame %d of %d\n', cnt, length(dirList));
                end
                
            else
                handle = visualizePointCloud(XYZworld,RGB,SLabel, 1, 100, handle); hold on;
                %view(160, -50)
                view(160, 0)
                pause(1);
            end
        end
    
end

end

if (vis == 2)
    isSampled = true;   
    spacingSize = 100;
    if (isSampled)
       pclRGB = pclRGB(:,1:spacingSize:end);
       pclSLabel = pclSLabel(:,1:spacingSize:end);
    end
    savepcd([sequenceName '/pcl_rgb.pcd'], pclRGB);    
    savepcd([sequenceName '/pcl_superlabel.pcd'], pclSLabel);      
end

if (vis == 3)    
    fid1 = fopen([sequenceName '/pcl_rgb.txt'], 'w');
    numberOfPts = size(pclRGB,2);
    for i=1:100:numberOfPts
        fprintf(fid1, '%f %f %f %d %d %d\n', pclRGB(1,i), pclRGB(2,i), pclRGB(3,i), pclRGB(4,i), pclRGB(5,i), pclRGB(6,i));    
        if (mod(i,1000) == 0)
            fprintf('loaded frame %d of %d\n', i, numberOfPts);
        end       
    end
    fclose(fid1);
    
%     fid2 = fopen([sequenceName '/pcl_superlabel.txt'], 'w');
%     fprintf(fid2, '%f %f %f %d %d %d', [pclSLabel(1,:)' pclSLabel(2,:)' pclSLabel(3,:)' pclSLabel(4,:)' pclSLabel(5,:)' pclSLabel(6,:)']);    
%     fclose(fid2);    
end

end

function f1 = visualizePointCloud(XYZ,RGB,SLabel, visSuperCat, subsampleGap, f1)
    if ~exist('subsampleGap','var')
        subsampleGap = 10;
    end
    if ~exist('visSuperCat','var')
        visSuperCat = 1;
    end    
    XYZ = XYZ(:,1:subsampleGap:end);
    RGB = RGB(:,1:subsampleGap:end);
    SLabel = SLabel(:,1:subsampleGap:end);
    
    figure(f1);
    if (visSuperCat)        
        scatter3(XYZ(1,:),XYZ(2,:),XYZ(3,:),ones(1,size(XYZ,2)),double(SLabel)'/255,'filled');
    else
        scatter3(XYZ(1,:),XYZ(2,:),XYZ(3,:),ones(1,size(XYZ,2)),double(RGB)'/255,'filled');            
    end    
    axis equal
    axis tight
end
