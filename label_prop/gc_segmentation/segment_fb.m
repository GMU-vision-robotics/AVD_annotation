% this function computes the figure/background segmentation of the image

% INPUT

% OUTPUT    
% Md. Alimoor Reza, November 2013
function segment_fb()
addpath GCmex
addpath emgm
addpath(genpath('~/work/libraries/vlfeat-0.9.19/'));
vl_setup;

close all;
par.gmm_K = 5;
LARGE_NUM = 1234567;
dir_name = dir('images/');
% read an image
for im_ii=11:length(dir_name)
    im_name = dir_name(im_ii).name;
    im = imread(['images/' dir_name(im_ii).name]);
    % im_name = 'blue_car';
    % im = im2double(imread(['images/' im_name '.png']));
    % src_im = im2double(imread(['images/' im_name  '_fg.png']));

    % % select the foreground area for modeling the foreground distribution
    imshow(im); title('Select the area for foreground');
    % extract foreground image for modeling the foreground likelihood
    [x y] = ginput(2);
    fg_im = im(y(1):y(2), x(1):x(2),:);
    r = fg_im(:,:,1);
    g = fg_im(:,:,2);
    b = fg_im(:,:,3);
    X_fg = [r(:) g(:) b(:)];
    close;
    
    imshow(im); title('select the area for background');
    
    % extract background image for modeling the background likelihood
    [x y] = ginput(2);
    bg_im = im(y(1):y(2), x(1):x(2),:);
    r = bg_im(:,:,1);
    g = bg_im(:,:,2);
    b = bg_im(:,:,3);
    X_bg = [r(:) g(:) b(:)];
    
    
%%%     doesn't converge.
%     options = statset('Display','final');
%     obj = gmdistribution.fit(X, 2,'Options',options, 'CovType', 'diagonal');
%     ComponentMeans = obj.mu
%     ComponentCovariances = obj.Sigma
    
    [label, model_fg, llh] = emgm(double(X_fg)', par.gmm_K);
    [label, model_bg, llh] = emgm(double(X_bg)', par.gmm_K);
     
%     [means, covariances, priors] = vl_gmm(X_fg', par.gmm_K) ;
%     [ model_fg ] = set_gmm_parameters( means, covariances, priors, par.gmm_K);
%     
%     [means, covariances, priors] = vl_gmm(double(X_bg)', par.gmm_K) ;
%     [ model_bg ] = set_gmm_parameters( means, covariances, priors, par.gmm_K);

    % try to segment the image into foreground and background regions
    sz_im = size(im);
    Dc = zeros([sz_im(1:2) 2],'double');
    % compute foreground likelihood map
    MM = compute_likelihood_gmm(im, model_fg, par.gmm_K);
    tmp = sum(MM,3);
    % display the likehood map of each pixel given foreground model
    f1 = figure;
    imagesc(tmp); title('foreground likelihood map');
    im_tmp = getframe(f1);
    imwrite(im_tmp.cdata, ['results/foreground/' im_name]); %keyboard;
    % convert the likelihood map into negative log likelihood for data term in graph cut.
    tmp(tmp == inf) = LARGE_NUM; tmp = -log(tmp);
    Dc(:,:,1) = tmp;
    pause;
    %keyboard;
    
    % compute background likelihood map
    MM = compute_likelihood_gmm(im, model_bg, par.gmm_K);
    tmp = sum(MM,3);
    % display the likelihood map given the background model
    f2 = figure;
    imagesc(tmp); title('background likelihood map');
    im_tmp = getframe(f2);
    imwrite(im_tmp.cdata, ['results/background/' im_name]);

    % convert the likelihood map to negative log likelihood that will be used as data term for graph cut.
    tmp(tmp == inf) = LARGE_NUM; tmp = -log(tmp);
    Dc(:,:,2) = tmp;

    pause;
    close all;
    %keyboard;

    % cut the graph

    % smoothness term: 
    % constant pairwise term
    Sc = ones(2) - eye(2);
    gch = GraphCut('open', Dc, 15*Sc);
    [gch L] = GraphCut('expand',gch);
    gch = GraphCut('close', gch);

    % show results
    f3 = figure;
    imshow(im); hold on;
    PlotLabels(L); 
    im_tmp = getframe(f3);
    imwrite(im_tmp.cdata, ['results/di_pairwise/' im_name]);
    pause; close all;
    
    % constrast sensitive pairwise term
    % spatialy varying part
    % [Hc Vc] = gradient(imfilter(rgb2gray(im),fspecial('gauss',[3 3]),'symmetric'));
    [Hc Vc] = SpatialCues(double(im));

    gch = GraphCut('open', Dc, 10*Sc, exp(-Vc*5), exp(-Hc*5));
    [gch L] = GraphCut('expand',gch);
    gch = GraphCut('close', gch);

    % show results
    f4 = figure;
    imshow(im); hold on;
    PlotLabels(L); 
    im_tmp = getframe(f4);
    imwrite(im_tmp.cdata, ['results/contrast_pairwise/' im_name]);
    pause; close all;

    
end


%---------------- Aux Functions ----------------%
function v = ToVector(im)
% takes MxNx3 picture and returns (MN)x3 vector
sz = size(im);
v = reshape(im, [prod(sz(1:2)) 3]);

%-----------------------------------------------%
function ih = PlotLabels(L)

L = single(L);

bL = imdilate( abs( imfilter(L, fspecial('log'), 'symmetric') ) > 0.1, strel('disk', 1));
LL = zeros(size(L),class(L));
LL(bL) = L(bL);
Am = zeros(size(L));
Am(bL) = .5;
ih = imagesc(LL); 
set(ih, 'AlphaData', Am);
colorbar;
colormap 'jet';

%-----------------------------------------------%
function [hC vC] = SpatialCues(im)
g = fspecial('gauss', [13 13], sqrt(13));
dy = fspecial('sobel');
vf = conv2(g, dy, 'valid');
sz = size(im);

vC = zeros(sz(1:2));
hC = vC;

for b=1:size(im,3)
    vC = max(vC, abs(imfilter(im(:,:,b), vf, 'symmetric')));
    hC = max(hC, abs(imfilter(im(:,:,b), vf', 'symmetric')));
end
