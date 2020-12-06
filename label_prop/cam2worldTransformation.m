 close all; clear; 

 
cd ~/research/ActiveVisionDataset/Home_001_1/
load image_structs.mat; 

 

 
% 2 image_structs(2)
depth1 = imread('high_res_depth/000110000020103.png'); 
im1 = imread('jpg_rgb/000110000020101.jpg');
image_structs(2).world_pos
R1 = inv(image_structs(2).R)
t1 = -R1*image_structs(2).t*scale/1000 

 
% 13 image_structs(13)
depth2 = imread('high_res_depth/000110000130103.png'); 
im2 = imread('jpg_rgb/000110000130101.jpg');
image_structs(13).world_pos
R2 = inv(image_structs(13).R)
t2 = -R2*image_structs(13).t*scale/1000

 
Rot1 = R1*R2'; trans1 = t1-R2'*t2
Rot2 = R1'*R2; trans2 = R1'*(t2-t1)

 
subplot(2,2,1); imagesc(depth1); 
subplot(2,2,2); imagesc(im1); title('view 1'); 

 
subplot(2,2,3); imagesc(depth2); 
subplot(2,2,4); imagesc(im2); title('view 2'); 

 
fx_rgb = 1.0477637710998533e+03;
fy_rgb = 1.0511749325842486e+03;
cx_rgb = 9.5926120509632392e+02;
cy_rgb = 5.2911546499433564e+02;

 
% scale = -6.23;
depth=double(depth2); depth=depth/1000;
col_depth = depth; 

 
center = [cx_rgb cy_rgb];
[imh, imw] = size(col_depth);
pcloud = zeros(imh,imw,3);

 
xgrid = ones(imh,1)*(1:imw) - center(1);
ygrid = (1:imh)'*ones(1,imw) - center(2);
pcloud(:,:,1) = xgrid.*col_depth/fx_rgb;
pcloud(:,:,2) = ygrid.*col_depth/fy_rgb;
pcloud(:,:,3) = col_depth;
l=size(pcloud,1)*size(pcloud,2);
X=reshape(pcloud(:,:,1), [l 1]); Y=reshape(pcloud(:,:,2), [l 1]); Z=reshape(pcloud(:,:,3), [l 1]);
R=reshape(im2(:,:,1), [l 1]); G=reshape(im2(:,:,2), [l 1]); B=reshape(im2(:,:,3), [l 1]);
valid=find(Z~=0);
X=X(valid); Y=Y(valid); Z=Z(valid);
R=R(valid); G=G(valid); B=B(valid);
pcl2=[X Y Z];
% figure; plot3(X(1:40:end), Y(1:40:end), Z(1:40:end), '.'); title('view 2'); 
% box on

 
figure; 
colorPtCloud = pointCloud(pcl2, 'Color', [R G B]);
pcshow(colorPtCloud);
title('view 2');
% keyboard; 

 
figure(100); hold on; 
pcl2_w = R2*pcl2' + repmat(t2,1,length(pcl2)); 
colorPtCloud = pointCloud(pcl2_w', 'Color', [R G B]);
pcshow(colorPtCloud);
title('view 2 projected to world');

 

 

 
depth=double(depth1); depth=depth/1000;
col_depth = depth; 

 
center = [cx_rgb cy_rgb];
[imh, imw] = size(col_depth);
pcloud = zeros(imh,imw,3);

 
xgrid = ones(imh,1)*(1:imw) - center(1);
ygrid = (1:imh)'*ones(1,imw) - center(2);
pcloud(:,:,1) = xgrid.*col_depth/fx_rgb;
pcloud(:,:,2) = ygrid.*col_depth/fy_rgb;
pcloud(:,:,3) = col_depth;
l=size(pcloud,1)*size(pcloud,2);
X=reshape(pcloud(:,:,1), [l 1]); Y=reshape(pcloud(:,:,2), [l 1]); Z=reshape(pcloud(:,:,3), [l 1]);
R=reshape(im1(:,:,1), [l 1]); G=reshape(im1(:,:,2), [l 1]); B=reshape(im1(:,:,3), [l 1]);
valid=find(Z~=0);
X=X(valid); Y=Y(valid); Z=Z(valid);
R=R(valid); G=G(valid); B=B(valid);
pcl1=[X Y Z];
% figure; plot3(X(1:40:end), Y(1:40:end), Z(1:40:end), '.'); title('view 2'); 
% box on

 
figure; 
colorPtCloud = pointCloud(pcl1, 'Color', [R G B]);
pcshow(colorPtCloud);
title('view 1');

 
figure(100); 
hold on; 
pcl1_w = R1*pcl1' + repmat(t1,1,length(pcl1)); 
colorPtCloud = pointCloud(pcl1_w', 'Color', [R G B]);
pcshow(colorPtCloud);
title('view 1 and 2 projected to world');