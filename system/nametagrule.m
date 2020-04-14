function nametags = nametagrule(namerule, protocol, tags, KV, mA)
% file name rule, usually for .raw, .corr and reconxml
% nametags = nametagrule(namerule, protocol, tags, KV, mA);
% or nametags = nametagrule(namerule, protocol);
% Then a typical rawdata filename is like this: ['rawdata' namekey nametags '_' 'v1.0' '.raw'],
% INPUT
%   namerule        to select a name rule, 'standard', 'simple', 'timestamp' or otherwise as default
%   protocol        protocol struct of simulation or recon which could be SYS.protocol or reconxml.protocol
%   tags            tags to appearr in name
%   KV, mA          to define the tag 'KV mA', in simulation we might once run multi KVmAs and loop them to set the output
%                   files' name

if nargin<3
    tags = [];
end
% tags from protocol
prototag = protocol2tag(protocol, tags);

% input KV mA?
if nargin > 3
    prototag.KV = [num2str(KV) 'KV'];
end
if nargin > 4
    prototag.mA = [num2str(mA) 'mA'];
end

switch lower(namerule)
    case 'standard'
        % standard name rule
        nametags = ['_' prototag.scan '_' prototag.bowtie '_' prototag.collimator ...
                '_' prototag.KV prototag.mA '_' prototag.Focalsize prototag.Focalspot '_' prototag.rotationspeed];
    case 'manutags'
        % by input tags
        nametags = cell2mat(cellfun(@(x) ['_' prototag.(x)], fieldnames(prototag)', 'UniformOutput', false));
    case 'simple'
        % series number and KVmA
        nametags = ['_' prototag.series '_' prototag.KV prototag.mA];
    case 'series'
        % only series number
        nametags = ['_' prototag.series];
    case {'time', 'timestamp'}
        % time stamp
        nametags = ['_' num2str(now, '%.10f')];
        pause(0.001);
    case 'timeseries'
        % series number . time stamp 
        nametags = ['_' prototag.series '.' num2str(now, '%.10f')];
        pause(0.001);
    otherwise
        % empty nametag
        nametags = '';
        % WARN: files could be overwrited due to repeated file names.
end

end


function prototag = protocol2tag(protocol, tags)
% get tags from ptotocol

if nargin<2
    tags = [];
end
% default tags
default_tags = {'series', 'scan', 'bowtie', 'collimator', 'KV', 'mA', 'Focalsize', 'Focalspot', 'rotationspeed'};
if isempty(tags)
    tags = default_tags;
end

prototag = struct();
Ntag = size(tags(:),1);
for itag = 1:Ntag
    switch lower(tags{itag})
        case {'series', 'seriesindex'}
            prototag.series = ['series' num2str(protocol.seriesindex)];
        case 'focalsize'
            prototag.(tags{itag}) = tagfocalsize(protocol.focalsize, tags{itag});
        case 'focalspot'
            prototag.(tags{itag}) = tagfocalspot(protocol.focalspot);
        case {'excbowtie', 'largebowtie'}
            % escape bowtie to air, large and small
            prototag.(tags{itag}) = exclargebowtie(protocol.bowtie);
        case 'kv'
            prototag.(tags{itag}) = [num2str(protocol.KV) tags{itag}];
        case 'ma'
            prototag.(tags{itag}) = [num2str(protocol.mA) tags{itag}];
        case 'kvma'
            % put KV mA together
            prototag.(tags{itag}) = [num2str(protocol.KV) 'KV' num2str(protocol.mA) 'mA'];
        case 'focal'
            % put focalsize focalspot together
            prototag.(tags{itag}) = [tagfocalsize(protocol.focalsize) tagfocalspot(protocol.focalspot)];
        case 'rotationspeed'
            prototag.(tags{itag}) = [num2str(protocol.rotationspeed) 'SecpRot'];
        case 'rotsec'
            prototag.(tags{itag}) = [sprintf('%0.2f',protocol.rotationspeed) 'sec'];
        case {'time', 'timestamp'}
            prototag.(tags{itag}) = num2str(now, '%.10f');
            pause(0.001);
        case 'timeseries'
            % series number . time stamp 
            prototag.(tags{itag}) = [num2str(protocol.seriesindex) '.' num2str(now, '%.10f')];
            pause(0.001);
        otherwise
            % try to define the tag by general rule
            if isfield(protocol, tags{itag})
                % scan, bowtie, collimator or other
                if ischar(protocol.(tags{itag}))
                    prototag.(tags{itag}) = protocol.(tags{itag});
                else
                    prototag.(tags{itag}) = num2str(protocol.(tags{itag}));
                end
            else
                tagsplit = regexp(tags{itag}, '_', 'split');
                if isfield(protocol, tagsplit{1})
                    prototag.(tagsplit{1}) = sprintf(tagsplit{2}, protocol.(tagsplit{1}));
                else
                    % copy the string
                    prototag.(['manu_' tags{itag}]) = tags{itag};
                end
            end
    end
    
end

end


function nametag = tagfocalsize(focalsize, tagkey)
% tag of focal size
switch focalsize
    case 1
        nametag = 'Small';
    case 2
        nametag = 'Large';
    otherwise
        nametag = num2str(focalsize);
end

if nargin>1
    % upper
    if all(isstrprop(tagkey, 'upper'))
        % ALL UPPER
        nametag = [upper(nametag) 'FOCAL'];
    elseif all(isstrprop(tagkey, 'lower'))
        % all lower
        nametag = [lower(nametag) 'focal'];
    elseif isstrprop(tagkey(1), 'upper')
        % First Upper
        nametag(1) = upper(nametag(1));
        nametag = [nametag 'Focal'];
    else
        % unknown request
        nametag = [nametag 'Focal'];
    end
else
    nametag = [nametag 'Focal'];
end

end


function focalspot = tagfocalspot(focalspot)
% tag of focal spot
Nspot = size(focalspot(:), 1);
if Nspot>1
    switch Nspot
        case 2
            focalspot = 'DFS';
        otherwise
            focalspot = num2str(focalspot);
    end
else
    switch focalspot
        case {1, 2}
            focalspot = 'QFS';
        case {3, 6}
            focalspot = 'DFS';
        otherwise
            focalspot = num2str(focalspot);
    end
end

end


function nametag = exclargebowtie(bowtie)
% tag of air, large or small bowtie
switch lower(bowtie)
    case {0, 'empty', 'air'}
        nametag = 'AIRBOWTIE';
    case {1, 'body', 'large'}
        nametag = 'LARGEBOWTIE';
    case {2, 'head', 'small'}
        nametag = 'SMALLBOWTIE';
    otherwise
        % do nothing
        1;
end
end

