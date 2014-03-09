function [vertices, faces, normals] = imsurface(labeledimage, boundary)
%
% [vertices, faces, normals] = imsurface(labeledimage, boundary)
%
% description:
%    calculates surfaces (vertices, faces) and surface normals for objects
%    in a labeled image
%
% input:
%    labeledimage   labeled object's image
%    boundary       (optional) close surface at specified boundaries either sublist of 'hwl' or bool array ([0 0 0])
%
% output:
%    vertices         vertices of each object surface as cell array
%    faces            faces
%    normals          (optional) normals
%
% See also: imsurfaceplot3d, impixelsurface, isosurface, isonormals, patch

if nargin < 2
   boundary = zeros(1, ndims(labeledimage));
end
if length(boundary) == 1
   boundary = boundary * ones(1,ndims(labeledimage));
end
if ischar(boundary)
   if strcmp(boundary, 'all')   
      boundary = 'pql';
   end
   bd = boundary;
   boundary = zeros(1,3);
   boundary(1) = ~isempty(strfind(bd, 'p'));
   boundary(2) = ~isempty(strfind(bd, 'q'));
   boundary(3) = ~isempty(strfind(bd, 'l'));
end
labeledimage = padarray(labeledimage, boundary);

label = imlabel(labeledimage);
isize = size(labeledimage);
nlabel = length(label);

vertices = cell(nlabel, 1);
faces = cell(nlabel, 1);
if nargout == 3
   normals = cell(nlabel, 1);
end

for i = 1:nlabel
   l = label(i);
   obj = labeledimage == l;
   
   % reduce calculation to bounding box
   [bmin, bmax] = imboundingbox(obj);
   bmin = max(bmin - 1, 1);
   bmax = min(bmax + 1, isize);
   obj = imextract(obj, bmin, bmax);
   
   % call isosurface / isonormals
   [f,v] = isosurface(obj, 0.5);
   if nargout == 3
      n = isonormals(obj, v);
   end
   
   % correct for x,y exchange and assign outputs
   v = v(:, [2 1 3]);  
   vertices{i} = v + repmat(bmin, size(v,1), 1) - 1;
   faces{i} = f;
   
   if nargout == 3
      normals{i} = n(:,[2 1 3]);
   end
   
end

end