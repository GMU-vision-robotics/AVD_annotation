clear; %close all;

colorCode = [0 0 0 ;%background
        0 0 255 ;%bed
        255 102 102 ;%#books
        0 0 20 ;%ceil
        0 102 204 ;%#books
        255 255 0 ; %floor
        0 204 204 ;%furn
        102 0 255 ;%#obj
        153 255 204 % painting
        102 0 0 ; % sofa
        255 0 255 ;%#table
        0 102 102 ;%#tv
        255 128 0 ;%wall
        192 192 192 ;%#window        
        ];
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  0: background
%  1: bed
%  2: books
%  3: ceiling
%  4: chair
%  5: floor
%  6: furniture-others
%  7: object-others
%  8: painting
%  9: sofa
% 10: table
% 11: tv
% 12: wall
% 13: window
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%cropping parameters, crop images to ramove the boarder 
x1 = 41; x2 = 600;
y1 = 46; y2 = 470;

options = 7;

if (options == 1)
%% TASK 1: energy-terms
objectName = {'background','bed','books','ceiling','chair','floor','furniture-others','object-others','painting','sofa','table','tv','wall','window'};

% INSTRUCT: select the index you want to demonstrate
ii=13;
curName = objectName{ii};
f = figure; %set(f, 'Visible', 'off');
imagesc(pwDataTermG(:,:,ii))
set(gca,'units','pixels');
set(gca,'units','normalized','position',[0 0 1 1]);
axis off;
axis tight;
saveas(f, ['energy_' curName '.png']); close(f);
end


if (options == 2)
%% TASK 2: Depth image save for the keyframes
% INSTRUCT: change the name of the video and the index of the file
sequenceName = 'hotel_umd40';
ii = 65;
curName = sprintf('depth_%04d',ii);
matFileName = [sequenceName '/depth/' curName '.mat'];
load(matFileName, 'depth');
f = figure; %set(f, 'Visible', 'off');
depth = depth(y1:y2,x1:x2);
imagesc(depth);
set(gca,'units','pixels');
set(gca,'units','normalized','position',[0 0 1 1]);
axis off;
axis tight;
saveas(f, [curName '.png']); close(f);
end


if (options == 3)
%% TASK 3: RGB image save for the keyframes
% INSTRUCT: change the name of the video and the index of the file
sequenceName = 'hotel_umd40';
ii = 65;
curName = sprintf('rgb_%04d',ii);
matFileName = [sequenceName '/RGB/' curName '.png'];
img = imread(matFileName);
f = figure; %set(f, 'Visible', 'off');
img = img(y1:y2,x1:x2,:);
imagesc(img);
set(gca,'units','pixels');
set(gca,'units','normalized','position',[0 0 1 1]);
axis off;
axis tight;
saveas(f, [curName '.png']); close(f);
end

if (options == 4)
%% TASK 4: GT-color-coded image + 3D colored point-cloud
% INSTRUCT: change the name of the video
sequenceName = 'hotel_umd40';
vis = 3; % 0 for matlab pcl vis; 1 for frame vis; 2 for pcd file creation from matlab
ii = 1;
matFileName = [sequenceName '/label/' sprintf('%04d',ii) '.mat'];
%load(matFileName, 'image', 'depth', 'label', 'imgOverlaid', 'superLabel', 'RGB', 'XYZworld', 'valid');                  
load(matFileName, 'mapLabel13');

%SLabel = zeros(3,size(mapLabel13,1)*size(mapLabel13,2));
SLabel = zeros(size(mapLabel13,1),size(mapLabel13,2),3);
R = zeros(size(mapLabel13,1),size(mapLabel13,2));
G = zeros(size(mapLabel13,1),size(mapLabel13,2));
B = zeros(size(mapLabel13,1),size(mapLabel13,2));
for iLabel=1:14
    idx = find( mapLabel13 == iLabel)';
    if (~isempty(idx))
        %SLabel(1,idx) = repmat(colorCode(iLabel,:)', 1, length(idx));

        R(idx) = repmat(colorCode(iLabel+1,1), 1, length(idx));
        G(idx) = repmat(colorCode(iLabel+1,2), 1, length(idx));
        B(idx) = repmat(colorCode(iLabel+1,3), 1, length(idx));
        
    end
end

SLabel(:,:,1) = R;
SLabel(:,:,2) = G;
SLabel(:,:,3) = B;

f = figure;

labelFullRes = SLabel; % later used for generating the point-cloud in 3D
SLabel = SLabel(y1:y2,x1:x2,:);
imagesc(SLabel);
set(gca,'units','pixels');
set(gca,'units','normalized','position',[0 0 1 1]);
axis off;
axis tight;
curName = sprintf('gt-label_%04d',ii);
%saveas(f, [curName '.png']); 
close(f);
    
% if (vis == 1) % create pcl file. it is useful for rotating large point-cloud file which is otherwise slow and clumsy in matlab.
%     curPcl = [XYZworld; double(RGB)/255]; % x y z r g b
%     pclRGB = [pclRGB curPcl];
% 
%     curPcl = [XYZworld; double(SLabel)/255]; % x y z r g b
%     pclSLabel = [pclSLabel curPcl];
%     if (mod(cnt,5) == 0)
%         fprintf('loaded frame %d of %d\n', cnt, length(dirList));
%     end
% 
% elseif (vis == 3) % create txt file which will be later used to convert to .vtk file. it is useful for rotating large point-cloud file which is otherwise slow and clumsy in matlab.
%     curPcl = [XYZworld; double(RGB)]; % x y z r g b
%     pclRGB = [pclRGB curPcl];
% 
%     curPcl = [XYZworld; double(SLabel)]; % x y z r g b
%     pclSLabel = [pclSLabel curPcl];
%     if (mod(cnt,5) == 0)
%         fprintf('loaded frame %d of %d\n', cnt, length(dirList));
%     end
% 
% else



    curName = sprintf('rgb_%04d',ii);
    matFileName = [sequenceName '/RGB/' curName '.png'];
    RGB = imread(matFileName); % full res. RGB image
    
    curName = sprintf('rgb_%04d',ii);
    matFileName = [sequenceName '/worldpc/' curName '.mat'];
    load(matFileName, 'XYZworld'); % 3x307200 matrix

    % find the valid indices (non-zero in depth value)
    curName = sprintf('depth_%04d',ii);
    matFileName = [sequenceName '/depth/' curName '.mat'];
    load(matFileName, 'depth');
    valid = find(depth ~= 0);
    
    % retain only the valid ones 
%     R = RGB(:,:,1); R = R(valid);
%     G = RGB(:,:,1); G = G(valid);
%     B = RGB(:,:,1); B = B(valid);
%     RGB = zeros(size(R),3);
%     RGB(:,:,1) = R; RGB(:,:,2) = G; RGB(:,:,3) = B;
    
    RGB = reshape(RGB, [3, size(RGB,1)*size(RGB,2)]);
    labelFullRes = reshape(labelFullRes, [3, size(labelFullRes,1)*size(labelFullRes,2)]);
    
    %labelFullRes = labelFullRes(:,valid);    
    %RGB = RGB(:,valid);
    %XYZworld = XYZworld(:,valid);
    handle = figure;

    handle = visualizePointCloud(XYZworld,RGB,labelFullRes,0, 25, handle); hold on;
    %view(160, -50)
    view(160, 0);
    pause(1);
% end

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

%% TASK 5: Superpixel generation
if (options == 5)
sequenceName = 'hotel_umd40';
ii = 65;
curName = sprintf('%04d',ii);
matFileName = [sequenceName '/super_pixels/' curName '.mat'];
load(matFileName, 'sp');
my_colormap = rand(5000, 3);
imwrite (label2rgb(sp, my_colormap), ['superpixels_' curName '.png']);
    
end

%% TASK 6: visualization of the propagated label
if (options == 6)
sequenceName = 'hotel_umd40';
ii = 65;
curName = sprintf('%04d',ii);
matFileName = [sequenceName '/label_pred_geom_only_13_with_smoothness_2.5/' curName '.mat'];
load(matFileName, 'smoothedPredCp');
% SLabel = zeros(size(mapLabel13,1),size(mapLabel13,2),3);
% R = zeros(size(mapLabel13,1),size(mapLabel13,2));
% G = zeros(size(mapLabel13,1),size(mapLabel13,2));
% B = zeros(size(mapLabel13,1),size(mapLabel13,2));
% for iLabel=1:14
%     idx = find( mapLabel13 == iLabel)';
%     if (~isempty(idx))
%         %SLabel(1,idx) = repmat(colorCode(iLabel,:)', 1, length(idx));
% 
%         R(idx) = repmat(colorCode(iLabel+1,1), 1, length(idx));
%         G(idx) = repmat(colorCode(iLabel+1,2), 1, length(idx));
%         B(idx) = repmat(colorCode(iLabel+1,3), 1, length(idx));
%         
%     end
% end
imwrite (label2rgb(smoothedPredCp, double(colorCode)/255), ['propagated_' curName '.png']);
    
end

if (options == 7)
%% TASK 3: RGB image save for the keyframes
% INSTRUCT: change the name of the video and the index of the file
sequenceName = 'hotel_umd40';
ii = 65;
load('65_superpixel.mat', 'limCur');
curName = sprintf('rgb_%04d',ii);
matFileName = [sequenceName '/RGB/' curName '.png'];
img = imread(matFileName);
f = figure; %set(f, 'Visible', 'off');
img = img(y1:y2,x1:x2,:);
%imagesc(img);
lim = limCur;
[cx,cy]             = gradient(double(lim));
gidx                = (abs(cx)+abs(cy))~=0;
figure(f);
I_                  = img;
[r, c, ~] = size(img);
I_(gidx)=255; I_(gidx+r*c)=0; I_(gidx+2*r*c)=0;
figure(f);
imagesc(I_); axis image; hold on;

set(gca,'units','pixels');
set(gca,'units','normalized','position',[0 0 1 1]);
axis off;
axis tight;
saveas(f, [curName '.png']); close(f);
end
