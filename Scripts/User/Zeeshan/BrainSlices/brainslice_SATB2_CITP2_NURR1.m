%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Brain Slices %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all

initialize()
bfinitialize
initializeParallelProcessing(12)

addpath('./Scripts/User/Zeeshan/BrainSlices/');

datadir = '/data/Science/Projects/StemCells/Experiment/BrainSections/';
dataname = 'Sample B Slide 33 SATB2 CUX2 NURR1 CTIP2';

lab = {'SATB2', 'CTIP2', 'NURR1'}

verbose = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Data Source %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%is = ImageSourceBF('/data/Server/smb/upload/Brain sections/Sample B Slide 33 SATB2 CUX2 NURR1 CTIP2.lsm');
is = ImageSourceBF([datadir  dataname '.lsm']);
clc
is.printInfo

%%

is.setReshape('S', 'Uv', [16, 22]);
is.setCellFormat('UV')
is.setRange('C', 1);
clc; is.printInfo

%%
%is.setRange('C', 1);
%is.plotPreviewStiched('overlap', 102, 'scale', 0.1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inspect Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%region = struct('U', [8:11], 'V', [9:12], 'C', 1);
%region = struct('U', 10, 'V', 11, 'C', 1, 'X', 1:300, 'Y', 1:300);
%region = struct('U', 10, 'V', 11, 'C', 1);
region = struct('U', 1+[9:10], 'V', 1+[10:11], 'C', 1);

imgs = is.cell(region);
size(imgs);

figure(1); clf
implottiling(imgs, 'link', false)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Align
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
sh = alignImages(imgs, 'alignment', 'RMS', 'overlap.max', 150);
stmeth = 'Interpolate';
%stmeth = 'Pyramid';

img = stitchImages(imgs, sh, 'method', stmeth);
figure(1); clf; implot(img)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stich Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% nuclear marker
is.resetRange();

%region2 = {':',':'};
region2 = {500:1900, 450:1850};

imgsCTIP2 = is.cell(region, 'C', 3);
imgsSATB2 = is.cell(region, 'C', 4);
imgsNURR1  = is.cell(region, 'C', 5);

% corect illumination and background

imgsAll = {imgsSATB2, imgsCTIP2, imgsNURR1};

parfor i = 1:3
   %imgsAll{i} = cellfunc(@(x) filterAutoContrast(x/max(x(:))), imgsAll{i});
   imgsAll{i} = cellfunc(@(x) x - imopen(x, strel('disk', 10)), imgsAll{i});
   imgsAll{i} = cellfunc(@(x) x - imopen(x, strel('disk', 150)), imgsAll{i});
end


%%
imgSt =cell(1,3);
th = [200, 50, 100];
th = [0,0,0];
for i = 1:3
   imgsS = stitchImages(imgsAll{i}, sh, 'method', stmeth);
   imgsS = imgsS(region2{:});
   %imgsS = filterAutoContrast(imgsS/max(imgsS(:)));
   
   figure(16);
   subplot(3,1,i); 
   hist(imgsS(:), 256);
   
   imgsS(imgsS < th(i)) = 0;
   imgSt{i} = imclip(imgsS, 0, 2000);
   
end

figure(1); clf; colormap jet
implottiling(imgSt')

%%
imgC = cat(3, 1.25* imgSt{1}, imgSt{2}, 1 * imgSt{3});
%imgC = imclip(imgC, 0, 2500);
imgC = imgC / max(imgC(:));

figure(2)
implottiling({imgC, imgC(:,:,1); imgC(:,:,2), imgC(:,:,3)}')


%%
figure(3); clf
subplot(3,1,1);
hist(flatten(imgC(:,:,1)), 256);
subplot(3,1,2);
hist(flatten(imgC(:,:,1)), 256);
subplot(3,1,3); 
hist(flatten(imgC(:,:,3)), 256);

%%
for c = 1:3
   figure(5); 
   subplot(3,1,c)
   dd = imgC(:,:,c);
   hist(dd(:), 256);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Filter Image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%imgBM = filterBM(imgC, 'profile', 'np', 'sigma', 30);

imgBM = filterBM(imgC, 'profile', 'np', 'sigma', 15);
figure(3); clf;
implottiling({imgC; imgBM})

%%
% 
% imgsM = {imgBM(:,:,1), imgBM(:,:,2), imgBM(:,:,3)};
% imgCm = cellfunc(@(x) filterMedian(x, 5), imgsM);
% imgCm = cat(3, imgCm{:});
% figure(3);
% implottiling({imgC; imgCm})

%imgBM = imgBM(300:500, 400:600, :);

clc
imgCf = imgBM;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgI = imgCf(:,:,1) + imgCf(:,:,2) + imgCf(:,:,3);
imgI = mat2gray(imgI);

%imgmask = img > 0.125;
%imgmask = img > 0.25;
imgmask = imgI > 0.075;
%imgmask = imopen(imgmask, strel('disk', 3));
%imgmask = postProcessSegments(bwlabeln(imgmask), 'volume.min', 50) > 0;

if verbose
   %max(img(:))
   
   figure(21); clf;
   set(gcf, 'Name', ['Masking'])
   implottiling({imoverlaylabel(imgI, double(imgmask));  imgmask})
end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SLIC Segmentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of pixels: typical cell 9x9
npxl = fix(1.1 * numel(imgI) / (8*7))

%segment
imgS = segmentBySLIC(imgCf, 'superpixel', npxl, 'compactness', 10);

if verbose
   imgSp = impixelsurface(imgS);
   figure(5); clf;
   implot(imoverlaylabel(imgCf, imgSp, false));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Postprocess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
max(imgS(:))

imgSP = imgS;

stats = imstatistics(imgSP, {'MinIntensity'}, imgI);
figure(7); clf; 
hist([stats.MinIntensity], 256)
%hist(imgI(:), 256)

%%
imgSP = postProcessSegments(imgS, imgI, 'intensity.min', 0.085, 'volume.min', 15, 'fillholes', false);

if verbose
   imgSp = impixelsurface(imgSP);
   figure(5); clf;
   implot(imoverlaylabel(imgCf, imgSp, false));
end

%%

imgSP2 = immask(imgSP, imgmask);
imgSP2 = imlabelapplybw(imgSP2, @(x) imopen(x, strel('disk', 2)));
imgSP2 = imlabelseparate(imgSP2);

% stats = imstatistics(imgSP, {'MinIntensity'}, imgI);
% figure(7); clf; 
% hist([stats.MinIntensity], 56)
%hist(imgI(:), 256)

imgSP2 = postProcessSegments(imgSP2, imgI, 'intensity.min', 0.085, 'volume.min', 15, 'fillholes', false);
%imgSP = postProcessSegments(imgSP, 'volume.min', 7, 'fillholes', false);
imgSP2 = imrelabel(imgSP2);
max(imgSP2(:))

if verbose
   imgSp = impixelsurface(imgSP2);
   figure(5); clf;
   implot(imoverlaylabel(imgCf, imgSp, false));
end

%%

imgSPP = imgSP2;
%stats = imstatistics(imgSPP, {'Volume', 'PixelIdxList', 'MedianIntensity', 'Perimeter', 'Extent', 'FilledArea'}, imgI);

%
% figure(78); clf; hist([stats.MinIntensity], 256);
% 
% if verbose 
%    figure(15);clf;
%    %scatter(bbarea, [stats.Area])
%    scatter([stats.Perimeter]/2/pi, sqrt([stats.Volume]/pi))
%    
%    figure(16); clf
%    hist([stats.MedianIntensity], 256);
%    
%    figure(17); clf;
%    scatter([stats.Volume], [stats.FilledArea]);
% end
% 
% %bbarea = [stats.BoundingBox]; bbarea = reshape(bbarea, 4, []);
% %bbarea = bbarea(3:4, :); bbarea = prod(bbarea, 1);
% 
% ids = zeros(1,length(stats));
% %ids = [stats.Extent] < 0.5; %* pi /4;
% ids = or(ids, [stats.FilledArea] > ([stats.Volume] + 10));
% ids = or(ids, 0.65 * ([stats.Perimeter]) / (2 * pi) >= sqrt([stats.Volume] / pi));
% %ids = or(ids, [stats.Volume] <= 3);
% %ids = or(ids, [stats.MedianIntensity] < 0.045);
% %ids = ~ids;
% 
% imgSPP = imgSP;
% for i = find(ids)
%    imgSPP(stats(i).PixelIdxList) = 0;
% end
% imgSPP = imrelabel(imgSPP);
% max(imgSPP(:))


if verbose 
   figure(6); clf;
   %implottiling({imoverlaylabel(imgCf, impixelsurface(imgSPP), false); imoverlaylabel(imgCf, imgSP, false)});
   
   statsF = imstatistics(imgSPP, {'PixelIdxList', 'Centroid'});
   
%    mode = 'MedianIntensity';
%    statsR = imstatistics(imgSP, stats, mode,  imgCf(:,:,1));
%    statsG = imstatistics(imgSP, stats, mode,  imgCf(:,:,2));
%    statsB = imstatistics(imgSP, stats, mode,  imgCf(:,:,3));
   
   mode = 'MedianIntensity';
   statsR = imstatistics(imgSPP, statsF, mode,  imgCf(:,:,1));
   statsG = imstatistics(imgSPP, statsF, mode,  imgCf(:,:,2));
   statsB = imstatistics(imgSPP, statsF, mode,  imgCf(:,:,3));
   
   si = size(imgI);
   R = zeros(si); G = R; B = R;
   for i = 1:length(stats);
      R(statsF(i).PixelIdxList) =  statsR(i).(mode);
      G(statsF(i).PixelIdxList) =  statsG(i).(mode);
      B(statsF(i).PixelIdxList) =  statsB(i).(mode);
   end
   imgCC = cat(3, R, G, B);
   
   figure(7); clf;
   implottiling({imgCf; imgCC});
   R = zeros(si); G = R; B = R;
   for i = 1:length(stats);
      R(statsF(i).PixelIdxList) =  statsR(i).(mode);
      G(statsF(i).PixelIdxList) =  statsG(i).(mode);
      B(statsF(i).PixelIdxList) =  statsB(i).(mode);
   end
   imgCC = cat(3, R, G, B);
   
   figure(7); clf;
   implottiling({imgCf; imgCC});
end

imglab = imgSPP;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Statistics 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc

stats = imstatistics(imglab, {'PixelIdxList', 'Centroid'});

mode = 'MedianIntensity';
statsR = imstatistics(imglab, stats, mode,  imgCf(:,:,1));
statsG = imstatistics(imglab, stats, mode,  imgCf(:,:,2));
statsB = imstatistics(imglab, stats, mode,  imgCf(:,:,3));
  
si = size(imgCf(:,:,1));
R = zeros(si); G = R; B = R;
R2 = imgCf(:,:,1); G2 = imgCf(:,:,2); B2 = imgCf(:,:,3);

for i = 1:length(stats);
   R(stats(i).PixelIdxList) =  statsR(i).(mode);
   G(stats(i).PixelIdxList) =  statsG(i).(mode);
   B(stats(i).PixelIdxList) =  statsB(i).(mode);
   
   R2(stats(i).PixelIdxList) =  0*statsR(i).(mode);
   G2(stats(i).PixelIdxList) =  0*statsG(i).(mode);
   B2(stats(i).PixelIdxList) =  0*statsB(i).(mode);
end
imgCC = cat(3, R, G, B);
imgCC2 = cat(3, R2, G2, B2);
statsCC = {statsR, statsG, statsB};

%%
%imglabc = imlabelapplybw(imglab, @bwulterode);
cc = fix([stats.Centroid]);
imglabc = zeros(size(imglab));
ind = imsub2ind(size(imglab), cc');
imglabc(ind) = 1;
imglabc = imdilate(imglabc, strel('disk', 2));


%%
h = figure(7); clf;
subreg = {[600:900], [550:950], ':'};
imgCfsub = imgCf(subreg{:});
imgCsub = imgC(subreg{:});
imglabsub = imglabc(subreg{:});

implot(imoverlaylabel(imgCsub, imglabsub > 0,false, 'color.map', [[0,0,0]; 0.2*[1,1,1]]));
axis off
xlabel([]); ylabel([])

saveas(h, [datadir, dataname, '_Segmentation_Seeds.pdf'])


h = figure(8); clf;
imgCCsub = imgCC(subreg{:});

implottiling({imgCsub; imgCCsub});
axis off
xlabel([]); ylabel([])

saveas(h, [datadir, dataname, '_Segmentation_Segments.pdf'])

%% 
h = figure(9); clf;
imgCCsub = imgCf(subreg{:});

implot(imgCCsub);
axis off
xlabel([]); ylabel([])

saveas(h, [datadir, dataname, '_Segmentation_Filtered.pdf'])


%%
h = figure(10); clf;
imgCCsub = imgCf(subreg{:});

implot(imgCCsub);
axis off
xlabel([]); ylabel([])

saveas(h, [datadir, dataname, '_Segmentation_Raw.pdf'])

%%
h = figure(11); clf;

%implot(filterAutoContrast(imgCf));
implot(imgCf);
axis off
xlabel([]); ylabel([])

%saveas(h, [datadir, dataname, '_Raw.pdf'])


%% Individual channels


for c = 1:3

   h = figure(11+c); clf;

   %implot(filterAutoContrast(imgCf));
   imgCfc = imgCf;
   imgCfc(:,:,setdiff([1,2,3], c)) = 0;
   implot(imgCfc);
   axis off
   xlabel([]); ylabel([])

   saveas(h, [datadir, dataname, '_Raw_' lab{c} '.pdf'])
end

%% 

figure(7); clf;
implottiling({imgCf, imgCC; imgCC2, imoverlaylabel(imgCf, imglabc> 0,false, 'color.map', [[0,0,0]; [1,0,0]])});


%% Flourescence in Space

xy = [stats.Centroid]';
cm = {'r', 'g', 'b'};
cl = [0.5, 0.6, 0.4];
%ct = [0.110, 0.0, 0.100]

figure(21); clf;
for c = 1:3
   fi = [statsCC{c}.(mode)]';
   fi = imclip(fi, 0, cl(c));
   
   figure(21);
   subplot(2,3,c+3);
   hist(fi, 256)
 
   subplot(2,3,c);
   %imcolormap(cm{c});
   colormap jet
   scatter(xy(:,1), xy(:,2), 10, fi, 'filled');
   xlim([0, size(imglab,1)]); ylim([0, size(imglab,2)]);
   title(lab{c});
   %freezecolormap(gca)
   
   h = figure(22); clf
   colormap jet
   scatter(xy(:,1), xy(:,2), 10, fi, 'filled');
   xlim([0, size(imglab,1)]); ylim([0, size(imglab,2)]);
   title(lab{c}); 
   colorbar('Ticks', [])
   
   %saveas(h, [datadir dataname '_Quantification_' lab{c} '.pdf']);
end



%% Flourescence Expression

figure(22); clf;
fi = cell(1,3);
for c = 1:3
   fi{c} = [statsCC{c}.(mode)]';
   fi{c} = imclip(fi{c},0, cl(c));
   fi{c} = mat2gray(fi{c});
end
 
pairs = {[1,2], [1,3], [2,3]};

np = length(pairs);

for n = 1:np
   subplot(1, np,n)
   %fi = imclip(fi, 0, cl(c));
   %scatter(fi{pairs{n}(1)}, fi{pairs{n}(2)}, 10, 'b', 'filled');
   scattercloud(fi{pairs{n}(1)}, fi{pairs{n}(2)});
   xlim([0,1]); ylim([0,1]);
   xlabel(lab{pairs{n}(1)}); ylabel(lab{pairs{n}(2)});
   %freezecolormap(gca)
end


for n = 1:np
   h = figure(50+n); clf;
   %fi = imclip(fi, 0, cl(c));
   %scatter(fi{pairs{n}(1)}, fi{pairs{n}(2)}, 10, 'b', 'filled');
   scattercloud(fi{pairs{n}(1)}, fi{pairs{n}(2)});
   xlim([0,1]); ylim([0,1]);
   xlabel(lab{pairs{n}(1)}); ylabel(lab{pairs{n}(2)});
   
   saveas(h, [datadir dataname '_Quantification_Scatter_' lab{pairs{n}(1)} ,'_' lab{pairs{n}(2)} '.pdf']);
   %freezecolormap(gca)
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Classify Cells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%[b, xp, yp] = roipoly;

xp = [-11.3328, 124.3497, 214.2787, 394.1368, 531.397, 627.6368, 717.5659, 771.2078, 845.3598, 927.4003, 1039.4172, 1126.1909, 1217.6976, 1277.6503, 1321.826, 1370.7348, 1395.978, 1403.8666, -22.3767, -11.3328];
yp = [389.4037, 196.924, 121.1943, 108.5726, 129.0828, 151.1706, 168.5253, 177.9916, 177.9916, 195.3463, 242.6774, 275.8091, 301.0524, 326.2956, 357.8497, 381.5152, 384.6706, 2.8666, -0.28885, 389.4037];
imgbad = ~poly2mask(xp',yp', size(imgI,1), size(imgI,2))';

figure(6); clf;
implot(imgbad)


%% histograms
figure(10); clf
for c= 1:3
   subplot(2,3,c); 
   d = imgCf(:,:,c);
   hist(d(:), 256);
end

for c= 1:3
   subplot(2,3,c+3); 
   d = imgCC(:,:,c);
   hist(d(:), 128);
end


%% classify

cth = {0.1, 0.15, 0.15};

clear neuroClass
for c = 1:3
   xy = fix([statsCC{c}.Centroid]);
   xy(1,xy(1,:) > size(imgI,1)) = size(imgI,1); xy(1,xy(1,:) < 1) = 1;
   xy(2,xy(2,:) > size(imgI,2)) = size(imgI,2); xy(2,xy(2,:) < 1) = 1;
   
   isgood = zeros(1, size(xy,2));
   for i = 1:size(xy, 2)
      isgood(i) = imgbad(xy(1,i), xy(2,i));
   end
   isgood = logical(isgood);

   neuroClass(c,:) = double(and([statsCC{c}.(mode)] > cth{c}, isgood));
end
neuroClassTotal = fix(neuroClass(1,:) + 2 * neuroClass(2,:) + 4 * neuroClass(3,:))+1;

%neuroClassColor = {[0,0,0]; [0.6,0,0]; [0,0.6,0]; [0.33,0.33,0]; [0,0.33,0]; [0.33,0,0.33]; [0,0.33,0.33]; [0.5,0.5,0.5]};

neuroClassColor = num2cell([0.285714, 0.285714, 0.285714;
   0.929412, 0.290196, 0.596078;
   0.462745, 0.392157, 0.67451;
   0.709804, 0.827451, 0.2;
   0.984314, 0.690196, 0.25098;
   0.976471, 0.929412, 0.196078;
   0.584314, 0.752941, 0.705882;
   0, 0.682353, 0.803922
   ], 2);

neuroColor = reshape([neuroClassColor{neuroClassTotal}], 3,[])';
size(neuroClassTotal)

R = zeros(si); G = R; B = R;
for i = 1:length(stats);
   R(stats(i).PixelIdxList) =  neuroColor(i,1);
   G(stats(i).PixelIdxList) =  neuroColor(i,2);
   B(stats(i).PixelIdxList) =  neuroColor(i,3);
end
imgClass = cat(3, R, G, B);


figure(7); clf;
implottiling({imgCf; imgClass});

%saveas(h, [datadir dataname '_Classification_Image' '.pdf']);


%% Class in Space

xy = [stats.Centroid]';
xy = xy(isgood, :);

h = figure(27)

colormap(cell2mat(neuroClassColor))
   
scatter(xy(:,1), xy(:,2), 5, neuroClassTotal(isgood), 'filled');
xlim([0, size(imglab,1)]); ylim([0, size(imglab,2)]);
title(lab{c});
%freezecolormap(gca)

pbaspect([1,1,1])

saveas(h, [datadir dataname '_Quantification_Space.pdf']);



%% Histogram of Cell Classes
 
ncls = length(neuroClassColor);

nstat = zeros(1,ncls);

for i = 1:ncls
   id = num2cell(dec2bin(i-1));
   id = id(end:-1:1);
   for k = length(id)+1:3
      id{k} = '0';
   end

   clslab{i} = '';
   for c = 1:3
      if id{c} == '1'
         clslab{i} = [clslab{i}, '_', lab{c}];
      end
   end
   clslab{i} = clslab{i}(2:end);
   if isempty(clslab{i})
      clslab{i} = 'None';
   end
   
   nstat(i) = sum(neuroClassTotal == i);
end

nc = num2cell(nstat);
tb = table(nc{:}, 'VariableNames', clslab)


%% save numbers
writetable(tb, [datadir dataname '_Counts.txt'])


%% hist

h = figure(10); clf; hold on

k = 1;
ord = [1, 5, 3, 6, 7, 8, 4, 2];
for i = ord
   bar(k, nstat(i), 'FaceColor', neuroClassColor{i});
   
   k = k + 1;
end

set(gca, 'XTickLabel', '')  
xlabetxt = strrep(clslab(ord), '_', '+');
n = length(clslab);
ypos = -max(ylim)/50;
text(1:n,repmat(ypos,n,1), xlabetxt','horizontalalignment','right','Rotation',35,'FontSize',15)
saveas(h, [datadir dataname '_Classification_Statistics' '.pdf']);



%% Channel Based Classification

col = {[1,0,0], [0,1,0], [0,0,1]};

clear imgsCC

for c = 1:3
   neuroClassC = neuroClass(c,:);

   C = zeros(si);
   for i = 1:length(stats);
      C(stats(i).PixelIdxList) =  neuroClassC(i);
   end
   imgClass = zeros([si, 3]);
   imgClass(:,:,c) = C;

   
   imgsCC{8 - 2 * (c - 1)} = imgClass;
   imgsCC{8 - 2 * (c - 1) -1} = imgray2color(3*imgCf(:,:,c), col{c});
end
   

neuroClassColor = {[0,0,0]; [0.6,0,0]; [0,0.6,0]; [0.33,0.33,0]; [0,0.33,0]; [0.33,0,0.33]; [0,0.33,0.33]; [0.5,0.5,0.5]};
neuroColor = reshape([neuroClassColor{neuroClassTotal}], 3,[])';

R = zeros(si); G = R; B = R;
for i = 1:length(stats);
   R(stats(i).PixelIdxList) =  neuroColor(i,1);
   G(stats(i).PixelIdxList) =  neuroColor(i,2);
   B(stats(i).PixelIdxList) =  neuroColor(i,3);
end
imgClass = cat(3, R, G, B);


imgsCC{1} = imgC;
imgsCC{2} = imgClass;


h = figure(8); clf;
implottiling(reshape(imgsCC, 2, 4)', 'titles', {'', '', '', '', 'merge', lab{:},})

saveas(h, [datadir dataname '_Classification_Channels' '.pdf']);

%%

