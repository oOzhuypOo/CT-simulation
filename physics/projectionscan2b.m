function [P, Pair, Eeff] = projectionscan2b(focalposition, detposition, bowtie, filter, samplekeV, detspect, detpixelarea, ...
    viewangle, couch, gantrytilt, phantom, method, echo_onoff, GPUonoff)
% the projection simulation, sub function


Nw = size(detspect(:),1);
Np = size(detposition, 1);
Nfocalpos = size(focalposition, 1);
NkeVsample = length(samplekeV(:));
Nview = length(viewangle(:));
Nviewpf = Nview/Nfocalpos;

% ini P & Eeff
P = cell(1, Nw);
Eeff = cell(1, Nw);
switch lower(method)
    case {'default', 1, 'photoncount', 2}
        P(:) = {zeros(Np, Nview)};
        Eeff(:) = {zeros(Np, Nview)};
    case {'energyvector', 3}
        P(:) = {zeros(Np*Nview, Nsample)};
        % No Eeff
    otherwise
        % error
        error(['Unknown projection method: ' method]);
end
Pair = cell(1, Nw);

% projection on bowtie and filter in collimation
[Dmu_air, L] = flewoverbowtie(focalposition, detposition, bowtie, filter, samplekeV);
% distance curse
distscale = detpixelarea./(L(:).^2.*(pi*4));
% energy based Posibility of air
for ii = 1:Nw
    switch lower(method)
        case {'default', 1}
            % ernergy integration
            Pair{ii} = (exp(-Dmu_air).*detspect{ii}) * samplekeV';
            Pair{ii} = Pair{ii}.*distscale;
        case {'photoncount', 2}
            % photon counting
            Pair{ii} = sum(exp(-Dmu_air).*detspect{ii}, 2);
            Pair{ii} = Pair{ii}.*distscale;
        case {'energyvector', 3}
            % maintain the components on energy
            Pair{ii} = exp(-Dmu_air).*detspect{ii};
            Pair{ii} = Pair{ii}.*distscale;
        otherwise
            % error
            error(['Unknown projection method: ' method]);
    end
    Pair{ii}(isnan(Pair{ii})) = 0;
end

% projection on objects (GPU)
% tic
% echo '.'
if echo_onoff, fprintf('.'); end
[D, mu] = projectinphantom(focalposition, detposition, phantom, samplekeV, viewangle, couch, gantrytilt, GPUonoff);
D = reshape(D, Np*Nfocalpos, Nviewpf, []);
% toc

% echo '.'
if echo_onoff, fprintf('.'); end
% tic
% prepare GPU 
if GPUonoff
    mu = gpuArray(single(mu));
    samplekeV = gpuArray(single(samplekeV));
    detspect = cellfun(@(x) gpuArray(single(x)), detspect, 'UniformOutput', false);
    % Nlimit = gpuArray(single(Nlimit));
    Np = gpuArray(single(Np));
    Nfocalpos = gpuArray(single(Nfocalpos));
    distscale = gpuArray(single(distscale));
    Dmu_air = gpuArray(Dmu_air);
    Dmu = gpuArray(zeros(size(Dmu_air), 'single'));   
end

% for i_lim = 1:Nlimit
for iview = 1:Nviewpf
    % echo '.'
    if echo_onoff && mod(iview, 100)==0, fprintf('.'); end
    % viewindex
    viewindex = (iview-1)*Nfocalpos + (1:Nfocalpos);

    % projection on objects    
    if ~isempty(D)
        Dmu = Dmu_air + squeeze(D(:, iview, :))*mu;
%         Pmu = Dmu0 + squeeze(D(:, iview, :))*mu;
    else
        Dmu = Dmu_air;
    end
       
    % energy based Posibility
    for ii = 1:Nw
        switch lower(method)
            case {'default', 1}
                % ernergy integration
                Dmu = exp(-Dmu).*detspect{ii};
                % for quanmtum noise
                Eeff{ii}(:, viewindex) = gather(reshape(sqrt((Dmu * (samplekeV'.^2))./sum(Dmu, 2)), Np, Nfocalpos));
                % Pmu = integrol of Dmu 
                Pmu =  Dmu * samplekeV';
                Pmu = Pmu(:).*distscale;
                P{ii}(:, viewindex) = gather(reshape(Pmu, Np, Nfocalpos));
            case {'photoncount', 2}
                % photon counting
                Dmu = exp(-Dmu).*detspect{ii};
                Pmu = sum(Dmu, 2).*distscale;
                P{ii}(:, viewindex) = gather(reshape(Pmu, Np, Nfocalpos));
            case {'energyvector', 3}
                % maintain the components on energy
                Dmu = exp(-Dmu).*detspect{ii};
                Dmu = reshape(Dmu, Np*Nfocalpos, []).*distscale;
                index_p = (1:Np*Nfocalpos) + Np*Nfocalpos*(iview-1);
                P{ii}(index_p, :) = gather(reshape(Dmu, Np*Nfocalpos, []));
            otherwise
                % error
                error(['Unknown projection method: ' method]);
        end
    end
end
% toc

end
