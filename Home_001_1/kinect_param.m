
% Transform a depth image into 3D world coordinates for the GMU Kitchen scenes dataset.
% Georgios Georgakis, 2016

% INPUT 
%   depth: depth image loaded from the dataset
%   scale: The scale discrepancy between real depth and COLMAP's z
%           dimension, as described in the paper.
%	    This can be found in the scale file in the website under Scripts.
%   cam1: camera pose information for the chosen frame. This is equal to
%           frames(i) for a given frame i, which can be loaded from 
%           gmu_scene_00#_reconstruct_info_frame_sort.mat
%   kinectParams: Struct that holds focal length and cx, cy from the Kinect
%           calibration. The values can be found in scene_pose_info/calib_color.yaml
%           fx_rgb = 1.0477637710998533e+03;
%           fy_rgb = 1.0511749325842486e+03;
%           cx_rgb = 9.5926120509632392e+02;
%           cy_rgb = 5.2911546499433564e+02;

% OUTPUT
%   w_pcl: 3d world coordinates

% Note that a different scale parameter is needed for each scene.
% As an extra option, the rgb img can also be passed in this function to
% get the color info for each 3d point (and uncomment the relevant lines).

function w_pcl = depth2world(depth, scale, cam1, kinectParams)

%%% get the appropriate COLMAP depth
depth=double(depth); depth=depth/1000;
col_depth = zeros(size(depth,1),size(depth,2));
a = find(depth~=0);
v = depth(a);
predicted_depth = v*scale;
col_depth(a) = predicted_depth;

%%% project the pixel coordinates in local frame 3D using the scaled depth of
% COLMAP, and the focal_length from calibration
center = [kinectParams.cx_rgb kinectParams.cy_rgb];
[imh, imw] = size(col_depth);
pcloud = zeros(imh,imw,3);
xgrid = ones(imh,1)*(1:imw) - center(1);
ygrid = (1:imh)'*ones(1,imw) - center(2);
pcloud(:,:,1) = -xgrid.*col_depth/kinectParams.fx_rgb;
pcloud(:,:,2) = ygrid.*col_depth/kinectParams.fy_rgb;
pcloud(:,:,3) = col_depth;

%%% transform the local pcloud to world coords given the camera poses from COLMAP
% need to use the inverse pose
Rw2c=cam1.Rw2c; Tw2c=cam1.Tw2c;
Rc2w = inv(Rw2c);
Tc2w = -Rc2w*Tw2c';

X=pcloud(:,:,1); Y=pcloud(:,:,2); Z=pcloud(:,:,3);
%R=img(:,:,1); G=img(:,:,2); B=img(:,:,3);
l=size(pcloud,1)*size(pcloud,2);
X=reshape(X, [l 1]); Y=reshape(Y, [l 1]); Z=reshape(Z, [l 1]);
%R=reshape(R, [l 1]); G=reshape(G, [l 1]); B=reshape(B, [l 1]);
valid=find(Z~=0);
X=X(valid); Y=Y(valid); Z=Z(valid);
%R=R(valid); G=G(valid); B=B(valid);
pcl=[X Y Z]; %color=[R G B];

w_pcl = bsxfun(@plus, Tc2w, Rc2w*pcl'); % W = Rc2w*pcl' + Tc2w;


