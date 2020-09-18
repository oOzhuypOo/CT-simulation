function [D, mu] = projectinphantomGPU(focalposition, detectorposition, phantom, samplekeV, viewangle, couch, gantrytilt)
% project in phantom(s) GPU version
% [D, mu] = projectinphantom(focalposition, detectorposition, phantom, samplekeV, viewangle, couch, gantrytilt);
% We know Dmu = D*mu; but which could lay out of memory.

% default viewangle(s) and couch
if nargin<5
    viewangle = 0;
    couch = 0;
end
if nargin<6
    couch = zeros(size(viewangle));
end
if nargin<7
    gantrytilt = zeros(size(viewangle));
end

if isempty(phantom)
    % do nothing
    D = [];
    mu = [];
    return;
end

% hard coeff
Cclass = 'single';
viewlimit = 128;

% size
Np = size(detectorposition, 1);
Nview = length(viewangle(:));
Nsample = length(samplekeV(:));
Nfocal = size(focalposition, 1);

% couch = reshape(couch, Nfocal, [], 3);
Nobject = phantom.Nobject;
Nviewperf = Nview/Nfocal;

% ini D & mu
D = zeros(Np*Nview, Nobject, Cclass);
mu = zeros(Nobject, Nsample, Cclass);

% to GPU
focalposition = gpuArray(cast(focalposition, Cclass));
detectorposition = gpuArray(cast(detectorposition, Cclass));
viewangle = reshape(viewangle, Nfocal, []);
viewangle = gpuArray(cast(viewangle, Cclass));
couch = gpuArray(cast(couch, Cclass));
gantrytilt = gpuArray(cast(couch, gantrytilt));

% ini D_i
D_i = zeros(Np, Nviewperf, Cclass, 'gpuArray');

for iobj = 1:phantom.Nobject
    % loop the objects
    parentobj = phantom.object_tree(iobj);
    object_i = phantom.object{iobj};
    % mu
    mu_i = interp1(object_i.material.samplekeV, object_i.material.mu_total, samplekeV);
    % mu fix
    if parentobj>0
        mu_parent = interp1(phantom.object{parentobj}.material.samplekeV, ...
            phantom.object{parentobj}.material.mu_total, samplekeV);
        mu_i = mu_i - mu_parent;
    end
    mu(iobj, :) = cast(mu_i, Cclass);
    
    % to GPU
    O_obj = gpuArray(cast(object.O, Cclass));
    invV_obj = gpuArray(cast(object.invV, Cclass));
    
    % fly focal
    for ifocal = 1:Nfocal
        % geometry projection in object
        [D_i(:, ifocal:Nfocal:end), ~] = intersection(focalposition(ifocal, :), detectorposition, object_i, 'views-ray', ...
            viewangle(ifocal, :), couch(ifocal:Nfocal:end, :), gantrytilt(ifocal:Nfocal:end));
    end
    %         D(:, iobj) = Dmu + D_i(:)*mu_i;
    D(:, iobj) = D_i(:);
end
% I know the Dmu = D*mu;

end


function [D, L] = intersectionGPU(A, B, object_O, object_invV, object_type, views, couch, Ztilt)

% swithc the object type
switch lower(object_type)
    case {'sphere', 'ellipsoid'}
        inkey = 'sphere';
    case 'cylinder'
        inkey = 'cylinder';
    case 'blade'
        inkey = 'blade';
    case {'cube', 'cuboid', 'parallelepiped', 'parallel hexahedron'}
        inkey = 'cube';
    case 'image2d'
        inkey = 'image2D';
%         isimage = true;
    case {'image3d', 'images'}
        inkey = 'image3D';
%         isimage = true;
    otherwise
        inkey = 'nothing';
end



end
