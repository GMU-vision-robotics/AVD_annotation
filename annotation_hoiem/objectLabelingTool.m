function objects = objectLabelingTool(im, objects, image_name)

MAX_LABEL_SIZE = 320;  % size of displayed label image (smaller is faster)

if strcmp(class(im), 'uint8')
    im = im2double(im);
end

[imh, imw, nb] = size(im);
if nb==1
    im = repmat(im, [1 1 3]);
end
grayim = repmat(rgb2gray(im), [1 1 3]);

s = MAX_LABEL_SIZE/max(size(im));
grayimsm = imresize(grayim(:, :, 1), s, 'bilinear');

if nargin<2
    objects.imsize = [imh imw];
    objects.ordering = [];
    objects.rawmask = [];
    objects.labels = zeros(imh, imw);
    objects.bnd = false(imh, imw);
    objects.name = {};
    objects.num = 0;        
end

figure(1)
displayImage(im, grayim, objects);

figure(2)
displayLabels(grayimsm, objects);
set(gca,'units','pixels');
set(gca,'units','normalized','position',[0 0 1 1]);
axis off;
axis tight;
saveas(gca, image_name);
pause(1);
%return;


disp('Instructions: ');
disp(' q: quit (when done with image)');
disp(' n: new object; type name of object');
disp('    then left-click polygon points, right click when done');
disp(' c: clear object')
disp(' a: add to object; draw polygon')
disp(' r: remove from object; draw polygon')
disp(' b: move object backward in depth ordering')
disp(' f: move object forward in depth ordering')

MODIFY = 0;
NEW_OBJECT = 0;
PointLabel = 0;
modtype = 0;
modobj = 0;

x = [];  y = []; 
while 1
    try
    figure(1)
    [tx, ty, tb] = ginput(1);
    tx = max(min(round(tx),imw),1);
    ty = max(min(round(ty),imh),1);

    if tb=='q'
       return; 
    elseif tb=='s'

    elseif tb=='n'
        disp('new object')
        NEW_OBJECT = 1;   
        name = input('Enter object name: ', 's');
    elseif tb==1 && (NEW_OBJECT || MODIFY>0)  % left click
        if isempty(x)
            x(1) = tx; y(1) = ty;
            hold on, plot(x, y, 'g.');
        else
            x(end+1) = tx;  y(end+1) = ty;
            plot(tx, ty, '*');
            plot(x(end-1:end), y(end-1:end), 'b--');                
        end
    elseif tb==3 && numel(x)>=3 % right click
        x(end+1) = x(1);  y(end+1) = y(1);
        
        if NEW_OBJECT                                   
            NEW_OBJECT = 0;
            objects = addNewObject(objects, x, y, name);
        else
            MODIFY = 0;
            clab = PointLabel;
            objects = modifyObject(objects, x, y, modobj, modtype);
        end 
        figure(1), displayImage(im, grayim, objects);
        figure(2), displayLabels(grayimsm, objects);
        x = [];  y = [];                  
    elseif (tb=='a' || tb=='r' || tb=='c') && isempty(x)        
        MODIFY = 1;
        modtype = tb;
        modobj = objects.labels(ty, tx);       
        if modobj==0
            disp('Press "a", "r", or "c" within the object region to modify it');
            MODIFY = 0;
            continue;
        end
        disp(['change region ' num2str(modobj) ' ' modtype])
        if tb=='c'
            objects = modifyObject(objects, x, y, modobj, modtype);
            figure(1), displayImage(im, grayim, objects);
            figure(2), displayLabels(grayimsm, objects);             
        end            
    elseif (tb=='f' || tb=='b') && isempty(x)        
        modtype = tb;
        modobj = objects.labels(ty, tx);          
        if modobj==0
            disp('Press "f" or "b" within the object region to change the ordering');
            continue;
        end        
        disp(['change depth order ' num2str(modobj) ' ' modtype])
        objects = modifyObject(objects, x, y, modobj, modtype);
        figure(1), displayImage(im, grayim, objects);
        figure(2), displayLabels(grayimsm, objects);        
    end
    catch
        disp(lasterr);
        figure(1), displayImage(im, grayim, objects);
        figure(2), displayLabels(grayimsm, objects);        
        %disp('You found a bug: please report this error and the circumstances to the author');
    end
end
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayImage(im, grayim, objects)

tmpim = im;
ind = repmat(objects.labels>0, [1 1 3]);
tmpim(ind) = grayim(ind)*0.67 + 0.33;

% red edges
ind = repmat(objects.bnd, [1 1 3]);
vals = cat(3, objects.bnd, false(size(objects.bnd)), false(size(objects.bnd)));

tmpim(ind) = vals(ind);

hold off, imagesc(tmpim), axis image


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displayLabels(grayim, objects)

labels = objects.labels;
sc = max(size(grayim))/max(size(labels));
if sc < 1 
    labels = imresize(labels, sc, 'nearest');
end

labim = label2rgb(labels);

% if sc < 1
%     labim = imresize(labim, sc, 'nearest');    
% end

[h,s,v] = rgb2hsv(labim);
v = v*0.5 + grayim(:, :, 1)*0.5;
hold off, imagesc(hsv2rgb(h,s,v));

%stats = regionprops(objects.labels, 'BoundingBox');
hold on
dx = max(size(grayim, 1), size(grayim, 2))*0.02;
for k = 1:objects.num
    name = [num2str(objects.ordering(k)) ': ' objects.name{k}];
    if any(objects.labels(:)==k)
        mask = (labels==k);
    else
        mask = objects.rawmask{k};
        if sc < 1
            mask = imresize(mask, sc, 'nearest');
        end         
    end
   
    [y, x] = find(mask);
    if ~isempty(y) && ~isempty(x)
        y = mean(y); x = x(round(end/2));
        text(x, y, name, 'FontWeight', 'Bold');
        %text(stats(k).BoundingBox(1)+dx, stats(k).BoundingBox(2)+10+dx, name);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function objects = addNewObject(objects, x, y, name)

objects.num = objects.num + 1;
N = objects.num;
objects.ordering(N) = N;
objects.rawmask{N} = poly2mask(x, y, objects.imsize(1), objects.imsize(2));
ind = (objects.labels==0) & objects.rawmask{N};
objects.labels(ind) = N;
objects.name{N} = name;
[gx, gy] = gradient(objects.labels);
objects.bnd = (gx~=0) | (gy~=0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function objects = modifyObject(objects, x, y, modobj, modtype)

N = modobj;
if modtype=='c'    
    newind = [(1:N-1) (N+1:objects.num)];
    objects.num = objects.num-1;    
    
    objects.ordering = objects.ordering(newind);
    [sval, sind] = sort(objects.ordering, 'ascend');
    objects.ordering(sind) = (1:objects.num);
    
    objects.rawmask = objects.rawmask(newind);
    %objects.labels(objects.labels==N) = 0;
    objects.name = objects.name(newind);
elseif modtype=='b'
    objects.ordering(N) = objects.ordering(N)+1.5;
    [sval, sind] = sort(objects.ordering, 'ascend');
    objects.ordering(sind) = (1:objects.num);    
elseif modtype=='f'
    objects.ordering(N) = objects.ordering(N)-1.5;
    [sval, sind] = sort(objects.ordering, 'ascend');
    objects.ordering(sind) = (1:objects.num);
elseif modtype=='a'
    mask = poly2mask(x, y, objects.imsize(1), objects.imsize(2));
    objects.rawmask{N} = objects.rawmask{N} | mask;
elseif modtype=='r'
    mask = poly2mask(x, y, objects.imsize(1), objects.imsize(2));
    objects.rawmask{N} = objects.rawmask{N} & ~mask;    
end

objects.labels = zeros(size(objects.labels));
for k = 1:objects.num
    N = find(objects.ordering==k);
    ind = (objects.labels==0) & objects.rawmask{N};    
    objects.labels(ind) = N;
end
[gx, gy] = gradient(objects.labels);
objects.bnd = (gx~=0) | (gy~=0);

  

