function nametags = nametagrule(namerule, protocol, KV, mA)
% file name rule, usually for .raw, .corr and reconxml
% nametags = nametagrule(namerule, protocol, KV, mA);
% or nametags = nametagrule(namerule, protocol);
% Then a typical rawdata filename is like this: ['rawdata' namekey nametags '_' 'v1.0' '.raw'],
% INPUT
%   namerule        to select a name rule, 'standard', 'simple', 'timestamp' or otherwise as default
%   protocol        protocol struct of simulation or recon which could be SYS.protocol or reconxml.protocol
%   KV, mA          to define the tag 'KV mA', in simulation we might once run multi KVmAs and loop them to set the output
%                   files' name

% KVmA tag
if nargin > 3
    KVmA = ['_' num2str(KV) 'KV' num2str(mA) 'mA'];
elseif nargin > 2
    KVmA = ['_' num2str(KV) 'KV'];
elseif length(protocol.KV)==1 && length(protocol.mA)==1
    % no input KV mA
    KVmA = ['_' num2str(protocol.KV) 'KV' num2str(protocol.mA) 'mA'];
else
    % no input KV mA, but set multi KvmA in protocol 
    KVmA = '';
    % NOTE: stupid behavior
end

switch lower(namerule)
    case 'standard'
        % standard name rule
        nametags = ['_' protocol.scan '_' protocol.bowtie '_' protocol.collimator ...
                KVmA '_' num2str(protocol.rotationspeed) 'secprot'];
    case 'simple'
        % series number and KVmA
        nametags = ['_series' num2str(protocol.series_index) KVmA];
    case 'series'
        % only series number
        nametags = ['_series' num2str(protocol.series_index)];
    case {'time', 'timestamp'}
        % time stamp
        nametags = ['_' num2str(now, '%.10f')];
        pause(0.001);
    case 'timeseries'
        % series number . time stamp 
        nametags = ['_' num2str(protocol.series_index) '.' num2str(now, '%.10f')];
        pause(0.001);
    otherwise
        % empty nametag
        nametags = '';
        % WARN: files could be overwrited due to repeated file names.
end

end