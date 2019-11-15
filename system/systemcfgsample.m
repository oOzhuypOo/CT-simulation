function SYS_cfg = systemcfgsample()
% return a default CT system config, just a sample

% path
SYS_cfg.path.main = 'D:\matlab\CTsimulation\';
SYS_cfg.path.matter = '~\physics\matter\';
SYS_cfg.path.IOstandard = '~\IO\standard\';
SYS_cfg.path.systemdata = 'D:\matlab\ct\BCT16\';

% world
SYS_cfg.world.elementsdata = '$matter\elements\';
SYS_cfg.world.materialdata = '$matter\material\';
SYS_cfg.world.samplekeV_range = [5, 150];
SYS_cfg.world.samplekeV_step = 1;
SYS_cfg.world.refrencekeV = 60;

% detector
SYS_cfg.detector.frame_base = '$systemdata\detector\detector_sample.corr';
SYS_cfg.detector.frame_extra = [];
SYS_cfg.detector.reponse = 1.0;
% ASG (on detector)
SYS_cfg.detector.ASG = [];
% fliter (on detector)
SYS_cfg.detector.filter = [];

% source
SYS_cfg.source.focalposition = [0 -568 0];
SYS_cfg.source.focaldistort = 0;
% SYS_cfg.source.focalsize = [0.7, 1.0];
SYS_cfg.source.tubedata = '$systemdata\tube\tube_spectrumdata_v1.0.corr';

% collimation
SYS_cfg.collimation.bowtie.bowtiedata = '$systemdata\collimation\bowtie_geometry_v1.0.corr';
SYS_cfg.collimation.bowtie.material = 'Teflon';
SYS_cfg.collimation.filter(1).thickness = 2.0;
SYS_cfg.collimation.filter(1).material = 'metalAl';
SYS_cfg.collimation.filter(2).thickness = 1.0;
SYS_cfg.collimation.filter(2).material = 'metalTi';
SYS_cfg.collimation.blades.blasesdata = '';

% console
SYS_cfg.console.protocaltrans = '';
SYS_cfg.console.dicomdictionary = '';

% simulation method
SYS_cfg.simulation.project = 'Geometry';
SYS_cfg.simulation.spectrum = 'Single';  % or Continue
SYS_cfg.simulation.detectsample = 1;
SYS_cfg.simulation.focalsample = 1;
SYS_cfg.simulation.quantumnoise = 0;
SYS_cfg.simulation.offfocal = 0;
SYS_cfg.simulation.scatter = 0;

% scatter paramters (TBC)
SYS_cfg.scatter = [];

% output
SYS_cfg.output.path = 'D:\matlab\data\simulation\';
SYS_cfg.output.namekey = '';
SYS_cfg.output.namerule = 'simple';
SYS_cfg.output.rawdataversion = 'vb1.0';
SYS_cfg.output.corrtable = 'air, beamharden';
SYS_cfg.output.corrversion = [];    % default

