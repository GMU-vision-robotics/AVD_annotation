
function [merged_plane_labels, plane_eq] = plane_fitting(RGB, depth)

dz = depth/1e3;

fx_rgb                       = 5.1885790117450188e+02;                                      % RGB Intrinsic Parameters (NYU camera parameter)
fy_rgb                       = 5.1946961112127485e+02;
cx_rgb                       = 3.2558244941119034e+02;
cy_rgb                       = 2.5373616633400465e+02;

%% Read the images
[r,c,cols] = size(RGB);

[xc, yc] = meshgrid(1:c, 1:r);
dx = (xc-cx_rgb).*dz/fx_rgb;
dy = (yc-cy_rgb).*dz/fy_rgb;

%% Interpretation parameters

% Nominal focal length for the Kinect's RGB camera
focal_length            = 525;

% min_points - minimum number of points in a planar segment
min_points              = 20; % 20

% ransac_trials - number of ransac trials to use
ransac_trials           = 40; %40

% inlier_threshold - threshold used to decide if a point is an inlier to a hypothesis
inlier_threshold        = 0.01;

% outlier_ratio - fraction of leftover points that triggers a recursive refit
outlier_ratio           = 0.25;

% inlier_ratio - ratio used in plane merging to decide whether to merge planes
inlier_ratio            = 0.90;

% dotpthreshold_m - dot product threshold - used in merging to decide if planes are sufficiently similar
dotpthreshold_m         = 0.1; % default 0.10

% max_planes - maximum number of merged planes
max_planes              = 100; % 50

% offset distance for data association
min_offset_diff         = 0.07;

floor_angle_limit       = 10;
min_wall_points         = 1000;
dotpthreshold_w         = cos (deg2rad(30));
sigma_w                 = 0.01;

dotpthreshold_l         = cos (deg2rad(20));

%% Disparity image

% W = 1000 ./ double(d);  % 1/depth where depth is in meters should be between 1/0.1 and 1/10
% W(d == 0) = NaN;

W = 1./double(dz);     % 1/depth where depth is in meters should be between 1/0.1 and 1/10
W(dz == 0) = NaN;
W(dz > 7) = NaN;  % JK ignore far away data - not accurate

SS_combine = 0; 
if SS_combine   
    %verbose = 0;
    %[Prob,MAP] = perFrameSegmentationCRF(RGB, dz, verbose);
    [Prob,MAP] = perFrameSegmentationCRF(RGB, dz);
    Prob_furn = Prob(:,:,3);
    Prob_furn = imresize(Prob_furn,2);
    %figure; imagesc(Prob_furn); title('Furniture');
    
    Prob_floor = Prob(:,:,1);
    Prob_floor = imresize(Prob_floor,2);
    %figure; imagesc(Prob_floor); title('Floor');
    
    Prob_struct = Prob(:,:,2);
    Prob_struct = imresize(Prob_struct,2);
    %figure; imagesc(Prob_struct); title('Structure');
    
    % Wall Labels WL
    %[ii,nm,ext] = fileparts(imfiles(fi).name);
    %imwrite (uint8(MAP*256/max(MAP(:))), strcat(nm, '_MAP.jpg'));    
end

[nrows,ncols,ch] = size(RGB);
slic_spxl = 0;
if slic_spxl
    regularizer = 500;
    regionSize = 30;
    
    labels2 = vl_slic(single(rgb2gray(RGB)), regionSize, regularizer) ;
    if( min(labels2(:)) == 0 )
        labels2 = labels2 + 1;
    end
    I2 = RGB;
    [gx,gy] = gradient(double(labels2));
    gmag = gx.^2+gy.^2;
    gidx = find(gmag>0);
    % figure(f1);
    I2 = RGB;
    I2(gidx)=255; I2(gidx+r*c)=0; I2(gidx+2*r*c)=0;
else
    SegmentationScriptV2;
end
    
[merged_plane_labels, plane_labels] = mxFindPlanes (W, uint32(labels2), focal_length, min_points, ransac_trials, inlier_threshold, ...
        outlier_ratio, inlier_ratio, dotpthreshold_m, max_planes);
   

% JK remove small connected components
% for each plane label computed how many connected components
% it has and remove the small ones - they typically result
% from spurius plane fits and far away from real planes
% JK remove the planes  which have very small support
remove_small_planes=0;
if remove_small_planes
    np = max(merged_plane_labels(:));
    l = 0;
    for k=1:np
        ss = find(merged_plane_labels == k);
        if length(ss) < min_wall_points
            merged_plane_labels(ss) = 0;
        else
            l = l+1;
            merged_plane_labels(ss) = l;
        end
    end
end

nplanes = max(merged_plane_labels(:));

% [xc, yc] = meshgrid(1:ncols, 1:nrows);
% dz = W;
% dx = (xc-ncols/2).*dz/focal_length; 
% dy = (yc-nrows/2).*dz/focal_length;

[pcloud, distance] = depthToCloud(depth);
dx = pcloud(:,:,1);
dy = pcloud(:,:,2);
dz = pcloud(:,:,3);

plane_eq = [];
% This could be done a bit more efficiently by sorting the labeled points
% Excluding label 0 which denotes unknown areas
for label = 1:nplanes    
    t = find(merged_plane_labels == label);  
    dzc = dz(t);  
    dxc = dx(t);
    dyc = dy(t);
    [ normSpxl ] = fitPlaneAffine( dxc, dyc, dzc );

    plane_eq = [plane_eq; normSpxl];
end  

% nplanes = max(merged_plane_labels(:));
% merged_planes = repmat(struct ('n', [], 'uvw', []), nplanes, 1);
% % This could be done a bit more efficiently by sorting the labeled points
% for label = 1:nplanes
% 
%     t = (merged_plane_labels == label);
% 
%     [r, c] = find(t);
% 
%     u = (c - (ncols/2)) / focal_length;
%     v = (r - (nrows/2)) / focal_length;
%     w = W(t);
% 
%     merged_planes(label).uvw = [u, v, w];
%     merged_planes(label).n = fitPlaneLSQ(merged_planes(label).uvw);
% end

