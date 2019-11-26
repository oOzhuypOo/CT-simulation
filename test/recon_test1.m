% recon test script for Axial

% clear;
% path
addpath(genpath('../'));

reconxml = 'D:\matlab\data\simulation\recon_series1.xml';
reconcfg = readcfgfile(reconxml);
if ~iscell(reconcfg.recon)
    reconcfg.recon = {reconcfg.recon};
end

% ii = 1;
% recon configure
recon_ii = reconcfg.recon{1};
cfgpath = recon_ii.IOstandard;
% cfgpath = '../IO/standard/';
% load raw data
raw = loaddata(recon_ii.rawdata, cfgpath);

% data flow
rawhead.Angle_encoder = [raw.Angle_encoder];
rawhead.Reading_Number = [raw.Reading_Number];
rawhead.Integration_Time = [raw.Integration_Time];
rawhead.Reading_Number = [raw.Reading_Number];
rawhead.Time_Stamp = [raw.Time_Stamp];
rawhead.mA = single([raw.mA]);
rawhead.KV = [raw.KV];
rawdata = single([raw.Raw_Data]);

% shot
Nshot = recon_ii.protocol.shotnumber;

% views
Nview = recon_ii.protocol.viewnumber;
viewangle = linspace(0, pi*2, Nview+1) + recon_ii.protocol.startangle;
viewangle = viewangle(1:end-1);
% that should be replaced by rawhead.Angle_encoder

% log2
Z0 = 16384;
rawdata = rawdata - Z0;
rawdata(rawdata<=0) = nan;
rawdata = -log2(rawdata) + log2(single(rawhead.Integration_Time));

% air correction
aircorrfile = recon_ii.pipe.Air.corr;
aircorr = loaddata(aircorrfile, cfgpath);
% most simplified
mAshift = log2(rawhead.mA) - log2(single(aircorr.mA));
rawdata = rawdata + aircorr.main + mAshift;

% HC
% HCscale = recon_ii.pipe.Housefield.HCscale;
mu_ref = 0.021139124532511;
HCscale = 1000*log(2)/mu_ref;
rawdata = rawdata.*HCscale;

% rebin
% load detector
detector_corr = loaddata(recon_ii.detector_corr, cfgpath);
detector_corr.position = reshape(detector_corr.position, [], 3);
Npixel = double(detector_corr.Npixel);
Nslice = double(raw(1).Slice_Number);
mid_U = single(detector_corr.mid_U);
Nps = Npixel*Nslice;
hx_ISO = detector_corr.hx_ISO;
% fan angles
focalposition = recon_ii.focalposition;
y = detector_corr.position(1:Npixel, 2) - focalposition(2);
x = detector_corr.position(1:Npixel, 1) - focalposition(1);
fanangles = atan2(y, x);
% I know the fanangles of each slice are equal
% d is the distance from ray to ISO
Lxy = sqrt(x.^2+y.^2);
d = -detector_corr.SID.*cos(fanangles);

% rebin 1
delta_view = pi*2/Nview;
f = fanangles./delta_view;
viewindex = double(floor(f));
interalpha = repmat(f-viewindex, Nslice, 1);
viewindex = viewindex + 1;  % start from 0
startvindex = mod(max(viewindex), Nview)+1;
viewindex = repmat(viewindex, Nslice, Nview) + repmat(0:Nview-1, Nps, 1);
vindex1 = mod(viewindex-1, Nview).*Nps + repmat((1:Nps)', 1, Nview);
vindex2 = mod(viewindex, Nview).*Nps + repmat((1:Nps)', 1, Nview);
% multi shot

A = zeros(Nps, Nview*Nshot);
for ishot = 1:Nshot
    start_ishot = (ishot-1)*Nps*Nview;
    viewindex = (1:Nview) + (ishot-1)*Nview;
    A(start_ishot+vindex1) = rawdata(:, viewindex).*repmat(1-interalpha, 1, Nview);
    A(start_ishot+vindex2) = A(start_ishot+vindex2) + rawdata(:, viewindex).*repmat(interalpha, 1, Nview);
    % start angle for first rebin view
    A(:, viewindex) = [A(:, (startvindex:Nview)+(ishot-1)*Nview) A(:, (1:startvindex-1)+(ishot-1)*Nview)];
end
% start angle
viewangle = [viewangle(startvindex:end) viewangle(1:startvindex-1)];
startviewangle = viewangle(1);

% rebin 2 (QDO)
% reorder
[a1, a2] = QDOorder(Npixel, mid_U);
s1 = ~isnan(a1);
s2 = ~isnan(a2);
N_QDO = max([a1, a2]);
d_QDO = nan(size(d));
d_QDO(a1(s1)) = d(s1);
d_QDO(a2(s2)) = -d(s2);
A_QDO = zeros(N_QDO, Nslice*Nview/2*Nshot);
A = reshape(A, Npixel, Nslice, Nview*Nshot);
index_s1 = (1:Nslice*Nview/2)' + (0:Nshot-1).*Nslice*Nview;
A_QDO(a1(s1), :) = A(s1, index_s1(:));
index_s2 = (Nslice*Nview/2+1:Nslice*Nview)' + (0:Nshot-1).*Nslice*Nview;
A_QDO(a2(s2), :) = A(s2, index_s2(:));

% interp
delta_t = hx_ISO/2.0;
t1 = ceil(min(d_QDO)/delta_t + 0.5);
t2 = floor(max(d_QDO)/delta_t + 0.5);
Nreb = t2-t1+1;
midchannel = -t1+1.5;
tt = ((t1:t2)-0.5)'.*delta_t;

fd = d_QDO./delta_t + 0.5;
dindex = floor(fd) - t1 + 2;
dindex(dindex<=0) = 1;
dindex(dindex>Nreb) = Nreb+1;
tindex = nan(Nreb+1, 1);
tindex(dindex) = 1:N_QDO;
tindex = fillmissing(tindex(1:end-1), 'previous');
interalpha = (tt - d_QDO(tindex))./(d_QDO(tindex+1)-d_QDO(tindex));

B_QDO = A_QDO(tindex,:).*(1-interalpha) + A_QDO(tindex+1,:).*interalpha;
B_QDO = permute(reshape(B_QDO, Nreb, Nslice, Nview/2, Nshot), [1 2 4 3]);
B_QDO = reshape(B_QDO, Nreb, Nslice*Nshot, Nview/2);

% BP
% bp parameter
parallelbeam.Np = Nreb;
parallelbeam.midchannel = midchannel;
% parallelbeam.midchannel = 474.75;
parallelbeam.delta_d = delta_t;
parallelbeam.h = 500/512;
parallelbeam.viewangle = single(viewangle(1:Nview/2));
% parallelbeam.viewangle = mod(viewangle - pi/2, pi*2);
parallelbeam.N = 512;

% read filter
fid = fopen('D:\matlab\data\simulation\BodySoft_QDO.res');
% fid = fopen('D:\matlab\ct\kernel\BodySoft.bin.res');
myfilter = fread(fid, inf, 'single=>single');
fclose(fid);

Bimage = zeros(parallelbeam.N, parallelbeam.N, Nslice*Nshot, 'single');
for islice = 1:Nslice*Nshot
	Bimage(:,:, islice) = filterbackproj2D(squeeze(B_QDO(:, islice, :)), parallelbeam, myfilter);
%     Bimage(:,:, islice) = single(filterbackproj2D(squeeze(B_QDO(:, islice, :)), parallelbeam));
end
