function system = systemconfigure(system_cfg)
% configure CT system

system = struct();

% path
if isfield(system_cfg, 'path')
    system.path = system_cfg.path;
end
% IO format govening
cfggov = system.path.IOstandard;

% world 
if isfield(system_cfg, 'world')
    system.world = system_cfg.world;
end

% detector
if isfield(system_cfg, 'detector')
    system.detector = struct();
    % copy
    system.detector.detector_corr = system_cfg.detector;
    % detector frame
    frame_base = system_cfg.detector.frame_base;
    if ~isempty(frame_base)
        % load frame_base
        detector_base = loaddata(frame_base, cfggov);
        system.detector.detector_corr = ...
            structmerge(system.detector.detector_corr, detector_base, true);
    end
    % extra frame
    if isfield(system_cfg.detector, 'frame_extra') && ~isempty(system_cfg.detector.frame_extra)
        % load frame_extra
        detector_extra = loaddata(system_cfg.detector.frame_extra, cfggov);
        system.detector.detector_corr = ...
            structmerge(system.detector.detector_corr, detector_extra, true);
    end
    % response
    if isfield(system_cfg.detector, 'spectresponse') && ~isempty(system_cfg.detector.spectresponse)
        % load detector response
        detector_resp = loaddata(system_cfg.detector.spectresponse, cfggov);
        system.detector.detector_corr = ...
            structmerge(system.detector.detector_corr, detector_resp, true); 
    end
    % crosstalk
    if isfield(system_cfg.detector, 'crosstalk') && ~isempty(system_cfg.detector.crosstalk)
        % load crosstalk
        detector_crosstalk =  loaddata(system_cfg.detector.crosstalk, cfggov);
        system.detector.detector_corr = ...
            structmerge(system.detector.detector_corr, detector_crosstalk, true);
    end
    % ASG (TBC)
end

% source
if isfield(system_cfg, 'source')
    system.source = struct();
    % copy
    system.source.tube_corr = system_cfg.source;
    % tube data
    tube_corr = loaddata(system_cfg.source.tubedata, cfggov);
    system.source.tube_corr = structmerge(system.source.tube_corr, tube_corr, true);
    % fill up values
    if ~isfield(system.source.tube_corr, 'focalposition')
        system.source.tube_corr.focalposition = system.detector.detector_corr.focalposition;
    end
end

% collimation
if isfield(system_cfg, 'collimation')
    system.collimation = struct();
    % bowtie
    if isfield(system_cfg.collimation, 'bowtie')
        % multi-bowtie
        if iscell(system_cfg.collimation.bowtie)
            bowtie = system_cfg.collimation.bowtie;
        else
            bowtie = num2cell(system_cfg.collimation.bowtie);
        end
        Nbowtie = length(bowtie(:));
        system.collimation.bowtie = cell(1, Nbowtie);
        system.collimation.bowtie(:) = {struct()};
        for ii = 1:Nbowtie
            % copy
            system.collimation.bowtie{ii}.bowtie_corr = bowtie{ii};
            % bowtie curve
            bowtie_corr = loaddata(bowtie{ii}.bowtiedata);
            system.collimation.bowtie{ii}.bowtie_corr = ...
                structmerge(system.collimation.bowtie{ii}.bowtie_corr, bowtie_corr, true);
        end
    end
    % filter
    if isfield(system_cfg.collimation, 'filter')
        system.collimation.filter = system_cfg.collimation.filter;
    end
    % blades
    if isfield(system_cfg.collimation, 'blade')
        % TBC
        1;
    end
end

% data collector (DCB)
if isfield(system_cfg, 'datacollector')
    system.datacollector = system_cfg.datacollector;
end

% simulation method
if isfield(system_cfg, 'simulation')
    system.simulation = system_cfg.simulation;
    % memory
    if ~isfield(system.simulation, 'memorylimit')
        system.simulation.memorylimit = 2.0;        % 2.0 = 2G
    end
    % extra artifacts:
    % quantumnoise
    if ~isfield(system.simulation, 'quantumnoise')
        system.simulation.quantumnoise = false;
    end
    % crosstalk
    if ~isfield(system.simulation, 'crosstalk')
        system.simulation.crosstalk = false;
    end
    % offfocal
    if ~isfield(system.simulation, 'offfocal')
        system.simulation.offfocal = false;
    end
end

% scatter parameters
% TBC

% calibration parameters
% TBC

% console
if isfield(system_cfg, 'console')
    system.console = system_cfg.console;
    % protocaltrans
    if ~isfield(system.console, 'protocaltrans')
        system.console.protocaltrans = struct();
    end
    % protocaltrans.collimationexplain
    if isfield(system.console.protocaltrans, 'collimatorexplain') && ...
            ~isempty(system.console.protocaltrans.collimatorexplain)
        system.console.protocaltrans = readcfgfile(system.console.protocaltrans.collimatorexplain);
    end
end

% output
if isfield(system_cfg, 'output')
    system.output = system_cfg.output;
    if ~isfield(system.output, 'namerule')
        system.output.namerule = '';
    end
end

return
