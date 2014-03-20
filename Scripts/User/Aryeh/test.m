


vVertices = [0,0,0;1,0,0;1,1,0];
vTriangles = [0,1,2];
vNormals = [0,0,1;0,0,1;0,0,1];
vTimeIndex = 0;

sf.AddSurface(vVertices, vTriangles, vNormals, vTimeIndex);


%%


nset = 800;
%nset = size(surf)
sfset = surf(1:nset);
fcset = fac(1:nset);
nmset = norm(1:nset);

%%

imarissetsurface('test', sfset, fcset, nmset);



%% 

% try to add all at once

sfmat = cell2mat(sfset);
fcmat = cell2mat(fcset);
nmmat = cell2mat(nmset);


%%

psize = imarisgetsize()
extend = imarisgetextend()
fac = (extend(2,:) - extend(1,:)) ./ psize;
%%

% vertices{i} = imarispixel2space(imaris, vertices{i});
verts = impixel2space(psize, extend, sfmat);
  

%%
nrmls = nmmat;
nrmls = nrmls .* repmat(fac, size(nrmls,1),1);



%%
nvert = cellfun(@length, sfset)

ntri = cellfun(@length, fcset)

%%


surf = imarisgetobject('test');

surf.RemoveAllSurfaces

tp = zeros(length(nvert), 1);


%%
surf.AddSurfacesList(verts, nvert, fcmat-1, ntri, nrmls, tp)


