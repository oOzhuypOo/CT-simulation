% function [dataflow, prmflow, status] = reconnode_crosstalkcali(dataflow, prmflow, status)
% crosstalk calibration
% [dataflow, prmflow, status] = reconnode_crosstalkcali(dataflow, prmflow, status)

% parameters to use in prmflow
Npixel = prmflow.recon.Npixel;
Nslice = prmflow.recon.Nslice;
Nps = Npixel*Nslice;
Nview = prmflow.recon.Nview;

% parameters to use
if ~isempty(status)
    caliprm = prmflow.pipe.(status.nodename);
else
    % for debug
    caliprm = struct();     
end

% format version of calibration table
if isfield(caliprm, 'corrversion')
    corrversion = caliprm.corrversion;
else
    corrversion = 'v1.0';
end

% debug test
Nmerge = 4;
Nslice_mg = Nslice/Nmerge;
% Npixelpermod = 16;

% Nppm = Npixelpermod;

% step #2 inverse bh and nl
% I know we should do step1 first, not now

% find out the input data, I know they are rawdata_bk1, rawdata_bk2 ...
datafields = findfields(dataflow, '\<rawdata_bk');
Nbk = length(datafields);
headfields = findfields(dataflow, '\<rawhead_bk');

% in which odd are the original value, even are the ideal value (fitting target)
% reshape
for ibk = 1:Nbk
    dataflow.(datafields{ibk}) = reshape(dataflow.(datafields{ibk}), Nps, Nview);
end


% I know the air corr is in prmflow.corrtable
Aircorr = prmflow.corrtable.Air;
Aircorr.main = reshape(Aircorr.main, Nps, []);
airrate = mean(Aircorr.main, 2);
% I know the beamharden corr is in prmflow.corrtable
BHcorr = prmflow.corrtable.Beamharden;
BHcorr.main = reshape(BHcorr.main, Nps, []);
% I know the nonlinear corr is in dataflow
NLcorr = dataflow.nonlinearcorr;
NLcorr.main = reshape(NLcorr.main, Nps, []);
% I know
HCscale = 1000;

% inverse the ideal data
for ibk = 2:2:Nbk
    % inverse Housefield
    dataflow.(datafields{ibk}) = dataflow.(datafields{ibk})./HCscale;
    for ipx = 1:Nps
        % inverse beamharden
        dataflow.(datafields{ibk})(ipx, :) = iterinvpolyval(BHcorr.main(ipx, :), dataflow.(datafields{ibk})(ipx, :));
    end
    % inverse air (almost)
%     dataflow.(datafields{ibk}) = dataflow.(datafields{ibk}) + airrate;
end
% inverse the original data
for ibk = 1:2:Nbk
    % inverse Housefield
    dataflow.(datafields{ibk}) = dataflow.(datafields{ibk})./HCscale;
    for ipx = 1:Nps
        % apply the non-linear corr
        dataflow.(datafields{ibk})(ipx, :) = iterpolyval(NLcorr.main(ipx, :), dataflow.(datafields{ibk})(ipx, :));
        % inverse beamharden
        dataflow.(datafields{ibk})(ipx, :) = iterinvpolyval(BHcorr.main(ipx, :), dataflow.(datafields{ibk})(ipx, :));
    end
    % inverse air (almost)
%     dataflow.(datafields{ibk}) = dataflow.(datafields{ibk}) + airrate;
end

% merge slice
Nslice_mg = Nslice/Nmerge;
for ibk = 1:Nbk
    dataflow.(datafields{ibk}) = reshape(mean(reshape(dataflow.(datafields{ibk}), Npixel, Nmerge, Nslice_mg*Nview), 2), ...
        Npixel*Nslice_mg, Nview);
end
% merge index range
index_range = zeros(2, Nslice_mg, Nview, Nbk/2);
for ibk = 1:Nbk/2
    dataflow.(headfields{ibk}).index_range = reshape(dataflow.(headfields{ibk}).index_range, 2, Nmerge, Nslice_mg*Nview);
    dataflow.(headfields{ibk}).index_range = [max(dataflow.(headfields{ibk}).index_range(1, :, :), [], 2); ...
                                             min(dataflow.(headfields{ibk}).index_range(2, :, :), [], 2)];
    dataflow.(headfields{ibk}).index_range = reshape(dataflow.(headfields{ibk}).index_range, 2*Nslice_mg, Nview);
    index_range(:,:,:, ibk) = reshape(dataflow.(headfields{ibk}).index_range, 2, Nslice_mg, Nview);
end





% p_crs = repelem(p_crs, 1, Nmerge);
% 
% % paramters for corr
% crosstalkcorr = caliprmforcorr(prmflow, corrversion);
% % copy results to corr
% crosstalkcorr.Nslice = Nslice;
% crosstalkcorr.order = 1;
% crosstalkcorr.mainsize = Nps;
% crosstalkcorr.main = p_crs;

% % to return
% dataflow.crosstalkcorr = crosstalkcorr;
% 
% % status
% status.jobdone = true;
% status.errorcode = 0;
% status.errormsg = [];
% 
% end