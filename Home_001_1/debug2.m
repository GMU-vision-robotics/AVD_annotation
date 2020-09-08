

% load(fullfile(src_dir, video_name, 'allKeyframes.mat'), 'trainKeyframes');
% keyframes = trainKeyframes;
% clear trainKeyframes;
% 
% 
% allFileNames = dir([spxl_dir '*.mat']);
% allFileNumbers = cell(1, length(allFileNames));
% for iF=1:length(allFileNames)
%    curFileNumber = allFileNames(iF).name(1:end-6); % last two digits: 03 means raw-depth image (superpixel saved by the raw-depth image name)
%    allFileNumbers{iF} = curFileNumber;
%    
% end

windowLen = 6;
kfList = keyframes;
kfIndexList = zeros(1, length(allframes));
for ikfList=1:length(kfList)        
    kfIndexList( find(strcmp(allframes, keyframes{ikfList})) ) = 1;
end

idxall = find(kfIndexList == 1);
idxcurr = find(strcmp(allframes, fileNameC) == 1);
tmp1 = idxall-idxcurr;

[~, ind] = min(abs(tmp1));
leftwindow = [];

if (ind - round(windowLen/2)) > 0
    leftwindow = idxall(( ind - round(windowLen/2) ):ind-1);
else
    leftwindow = idxall(1:ind-1);
end

rightwindow = []; % includes the 'ind'
if ((round(windowLen/2) + ind) <= length(idxall))
    rightwindow = idxall(ind:ind+round(windowLen/2));
else
    rightwindow = idxall(ind:end);
end

leftwindow
rightwindow
windowKeyframeIndex = [leftwindow rightwindow];
windowKeyframeNames = {};

for iw=1:length(windowKeyframeIndex)
    windowKeyframeNames = cat(2, windowKeyframeNames, allframes{windowKeyframeIndex(iw)});
end
