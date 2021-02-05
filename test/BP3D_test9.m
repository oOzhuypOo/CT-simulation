% BP test code
% for 3D Axial slope rebin, shots fill up
% final test

% load('E:\data\simulation\TM\test\tilt_test3.mat');

% inputs are dataflow, prmflow
if exist('df0', 'var')
    dataflow = df0;
    clear df0;
end

if exist('pf0', 'var')
    prmflow = pf0;
    clear pf0;
end

% detector = prmflow.system.detector;
% SID = detector.SID;
% SDD = detector.SDD;
% delta_z = detector.hz_ISO;
SID = prmflow.recon.SID;
delta_z = prmflow.recon.delta_z;
Nshot = prmflow.recon.Nshot;
FOV = prmflow.recon.FOV;
Nviewprot = prmflow.recon.Nviewprot;
startviewangle = prmflow.recon.startviewangle + pi/2;
imagesize = prmflow.recon.imagesize;
midchannel = prmflow.recon.midchannel;
delta_d = prmflow.recon.delta_d/SID;
Npixel = prmflow.recon.Npixel;
Nslice = prmflow.recon.Nslice;
Nimage = prmflow.recon.Nimage;
% imageincrement = prmflow.recon.imageincrement;
% imageincrement = delta_z;
imageincrement = 0.6;   % imageincrement<delta_z

imagecenter = prmflow.recon.imagecenter;
couchdirection = prmflow.recon.couchdirection;
gantrytilt = single(prmflow.recon.gantrytilt);

FOV = 300;
h = FOV/imagesize;
Rfov = FOV/2*(sqrt(2)+1)/2;
Nedge = floor((Nslice*delta_z/2 - (sqrt(SID^2-Rfov^2) - Rfov)/SID*(Nslice-1)/2*delta_z)/imageincrement) + 2;
Nedge = min(Nedge, Nslice/2);
Nextslice = Nslice + Nedge*2;
% Nextslice = Nslice*2;
gpuDevice;

% reshape
dataflow.rawdata = reshape(dataflow.rawdata, Npixel, Nslice, Nviewprot, Nshot);


% ini image
img = zeros(imagesize, imagesize, Nimage, 'single');

xygrid = gpuArray(single((-(imagesize-1)/2 : (imagesize-1)/2).*(h/SID)));
[X, Y] = ndgrid(xygrid);
X = X(:);
Y = Y(:);
XY = [X Y];

index_np = gpuArray([Nslice/2+1:Nslice  1:Nslice/2]);


viewangle_prot = gpuArray(single(linspace(0, pi*2-pi*2/Nviewprot, Nviewprot)));

% edge expand 
Nfill0 = 4;

% ini GPU buffer
Nviewprot_gpu = gpuArray(single(Nviewprot));
Nslice_gpu = gpuArray(single(Nslice));
Nedge_gpu = gpuArray(single(Nedge));
Nextslice_gpu = gpuArray(single(Nextslice));
Nfill0_gpu = gpuArray(single(Nfill0));
midchannel_gpu = gpuArray(midchannel);
SID_gpu = gpuArray(SID);
imagesize_gpu = gpuArray(single(imagesize));
% delta_z_norm = gpuArray(delta_z/imageincrement/SID);
delta_d = gpuArray(delta_d);
Eta = zeros(imagesize*imagesize, 1, 'single', 'gpuArray');
Zeta = zeros(imagesize*imagesize, 1, 'single', 'gpuArray');
Tz = zeros(imagesize*imagesize, Nextslice, 'single', 'gpuArray');
t_chn = zeros(imagesize*imagesize, 1, 'single', 'gpuArray');
data_0 = zeros(imagesize*imagesize, Nslice+Nfill0*2, 'single', 'gpuArray');
data_iview = zeros(Npixel, Nslice, 'single', 'gpuArray');
alpha = zeros(imagesize*imagesize*Nextslice, 1, 'single', 'gpuArray');
beta = zeros(imagesize*imagesize*Nextslice, 3, 'single', 'gpuArray');
gamma = zeros(imagesize*imagesize, Nextslice, 'single', 'gpuArray');

index_img = repmat((1:imagesize_gpu*imagesize_gpu)', 1, Nextslice);
img_shot = zeros(imagesize, imagesize, Nextslice, 'single', 'gpuArray');

channelindex = gpuArray(single(1:Npixel)');



% z interp prepare
Nzs = 512;
Rs = min(500, FOV*sqrt(2))/SID;
zeta_samp = linspace(-Rs/2, Rs/2, Nzs);
eta_samp = linspace(-Rs/2, Rs/2, Nzs);
% [zeta_s, eta_s] = ndgrid(zeta_samp, eta_samp);
[zeta_s, eta_s] = meshgrid(zeta_samp, eta_samp);
t_samp1 = axialconehomeomorph(eta_s, zeta_s, Nslice, gantrytilt);
Nleft = -Nslice/2+1-Nfill0+3/2;
t_samp1(t_samp1<Nleft) = Nleft;
Nright = Nslice/2+Nfill0-3/2;
t_samp1(t_samp1>Nright) = Nright;
t_samp1 = t_samp1 + Nslice/2+Nfill0;



% to gpu
zeta_samp = gpuArray(zeta_samp);
eta_samp = gpuArray(eta_samp);
zz_samp = -Nslice_gpu+1:Nslice_gpu;
t_samp1 = gpuArray(t_samp1);
% r_samp = gpuArray(r_samp);
% theta_samp = gpuArray(theta_samp);
% t_samp2 = gpuArray(t_samp2);
z_target = repmat(-Nextslice_gpu/2+1 : Nextslice_gpu/2, imagesize*imagesize, 1);

Rxy = sqrt(X.^2+Y.^2);
thetaxy = atan2(Y, X);

% interp prepare
Nintp = 512;
alpha_intp = gpuArray(single(linspace(0, 1, Nintp+1)'));
index_intp = gpuArray(single(1:Nintp+1));
Nintp_gpu = gpuArray(single(Nintp));

% coeff
gamma_coeff1 = 0.6;
gamma_coeff2 = 1.4;
% gamma_coeff1 = gpuArray(gamma_coeff1);
% gamma_coeff2 = gpuArray(gamma_coeff2);

% Chninterp
Chninterp.delta_d = delta_d;
Chninterp.midchannel = midchannel_gpu;
Chninterp.channelindex = channelindex;

% Zinterp
% Zinterp.Nfill0 = Nfill0;
% Zinterp.Zeta = zeta_samp;
% Zinterp.Eta = eta_samp;
% Zinterp.zz = zz_samp;
% Zinterp.t = t_samp1;
% Zinterp.fourpointindex = index_intp;
% beta_intp = 1/2-sqrt(1+alpha_intp.*(1-alpha_intp).*4)./2;
% Zinterp.fourpoint = [(1+alpha_intp-beta_intp)./2  (alpha_intp+beta_intp)./2  ...
%           (gamma_coeff1/4)./sqrt(1-alpha_intp.*(1-alpha_intp).*gamma_coeff2)];
% Zinterp.Nfourp = Nintp_gpu;
% Zinterp.convL = gpuArray(single([-1 2 -1]));
maxFOV = 500;
Zinterp = omiga4table([gamma_coeff1, gamma_coeff2], [Nzs Nintp], maxFOV, FOV, SID, Nslice, gantrytilt);
Zinterp = everything2single(Zinterp, 'any', 'gpuArray');

% Nshot = 1;
for ishot = gpuArray(1:Nshot)
% for ishot = 1:1
tic;
    imageindex = (1:Nextslice) + ((ishot-1)*Nslice-(Nextslice-Nslice)/2);
    gatherindex = 1:Nextslice;
    shotflag = 0;
    if ishot==1
        imageindex(1:(Nextslice-Nslice)/2) = [];
        gatherindex(1:(Nextslice-Nslice)/2) = [];
        shotflag = 1;
    end
    if ishot==Nshot
        imageindex(end-(Nextslice-Nslice)/2+1:end) = [];
        gatherindex(end-(Nextslice-Nslice)/2+1:end) = [];
        shotflag = 2;
    end
    if Nshot==1
        shotflag = 3;
    end

    viewangle = viewangle_prot + startviewangle(ishot);  
    
    img_shot = backproj3Dslope(dataflow.rawdata(:, :, :, ishot), viewangle, XY, Nedge, Chninterp, Zinterp, shotflag, '4points', true);
    % get img
    img(:,:,imageindex) = img(:,:,imageindex) + reshape(gather(img_shot), imagesize, imagesize, []);
    fprintf('\n');
toc;
end

img = img.*(pi/Nviewprot/2);
