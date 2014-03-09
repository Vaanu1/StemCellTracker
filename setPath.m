function setPath()
%
% path = setPath()
%
% description:
%     sets all necessary paths
%

addpath('./Classes', ...
        './Filtering', ...
        './Segmentation', ...
        './Tracking',...
        './Interface',...
        './Interface/ImageFormats',...
        './Interface/ImageJ',...
        './Interface/Imaris',...
        './Utils',...
        './Utils/ImTools',...
        './Scripts');
     
addpath('./Test');
       
     
% compability to matlab previous versions
v = version('-release');
if length(v) >= 4
   v = v(1:4);
   if strcmp(v, '2012')
      addpath('./Utils/External/Matlab2012');
   end
end



      
end

