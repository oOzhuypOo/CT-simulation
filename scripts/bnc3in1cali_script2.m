% run after bnc3in1cali_script2 or bnc3in1cali_script1

%% step3. non-linear #2

% inputs
% BHcalitable, output of step1
% I know 
BHcalitable_file = 'E:\matlab\CT\SINO\PG\calibration\BHcalitable.mat';
% BHcalitable_file = 'D:\matlab\ct\BCT16\calibration\1\BHcalitable.mat';
tmp = load(BHcalitable_file);
BHcalitable = tmp.BHcalitable;
% crosstalk table, output of step2
% TBC

% % configure files for TM
% calioutputpath = 'E:\data\calibration\bh\';
% system_cfgfile = 'E:\matlab\CT\SINO\TM\system_configure_TM_cali.xml';
% protocol_cfgfile = 'E:\matlab\CT\SINO\TM\protocol_nonlinear.xml';
% configure files for PG
calioutputpath = 'E:\matlab\CT\SINO\PG\calibration\';
system_cfgfile = 'E:\matlab\CT\SINO\PG\system_configure_PGcali.xml';
protocol_cfgfile = 'E:\matlab\CT\SINO\PG\protocol_nonlinear.xml';

% % configure files of simulation sample
% calioutputpath = 'D:\matlab\ct\BCT16\calibration\1\';
% system_cfgfile = 'D:\matlab\ct\BCT16\BHtest\system_cali.xml';
% protocol_cfgfile = 'D:\matlab\CTsimulation\cali\calixml\protocol_nonlinear.xml';

% rawdata
rawdata_file = struct();
rawdata_file.body = {[], [], [], []};
rawdata_file.head = {[], [], [], []};
% % my data (TM)
% myrawpath = 'E:\data\rawdata\bhtest\';
% air_body = [myrawpath 'rawdata_air_120KV300mA_large_v1.0.raw'];
% water_body = {'rawdata_water200c_120KV300mA_large_v1.0.raw', 'rawdata_water200off100_120KV300mA_large_v1.0.raw', ...
%               'rawdata_water300c_120KV300mA_large_v1.0.raw', 'rawdata_water300off100_120KV300mA_large_v1.0.raw'};
% rawdata_file.body{3} = {air_body, [myrawpath water_body{1}], [myrawpath water_body{2}], [myrawpath water_body{3}], ...
%                         [myrawpath water_body{4}]};
% my data (PG)
myrawpath = 'F:\data-Dier.Z\PG\water\';
air_head3 = [myrawpath 'AIR\120KV\2.1581825424007.pd'];
water_head3 = {'22CM_WATER_CENTER\120\2.1581825763023.pd', '22CM_WATER_OFFSET9CM\120\2.1581825943035.pd', ...
               '30CM_WATER_CENTER\120\2.1581826503071.pd', '30CM_WATER_OFFSET10CM\120\2.1581826342059.pd'};
rawdata_file.head{3} = {air_head3, [myrawpath water_head3{1}], [myrawpath water_head3{2}], [myrawpath water_head3{3}], ...
                        [myrawpath water_head3{4}]};
                    
% scan data method
scan_data_method = 'prep';      % 'prep', 'real' or 'simu'.

% phantom
% I know the phantoms to scan are air, small water center/off and big water center/off
phantoms = {'phantom_air', 'phantom_shellwater200_center', 'phantom_shellwater200_off90', ...
            'phantom_shellwater300_center', 'phantom_shellwater300_off90'};
phatompath = 'E:\matlab\CTsimulation\system\mod\phantom\';
Nphantom = length(phantoms);    % =5
phatomfiles = cell(1, Nphantom);
for iph = 1:Nphantom
    phatomfiles{iph} = fullfile(phatompath, [phantoms{iph} '.xml']);
end

% bad channel
% badchannelindex = [2919 12609];     % sample
badchannelindex = [];
% pipe for air calibration (online air correction)
pipe_air = struct();
pipe_air.Log2 = struct();
pipe_air.Badchannel.badindex = badchannelindex;
pipe_air.Aircali = struct();
pipe_air.corrredirect.nodes = 'Air';                    % copy the table to prmflow
pipe_air.dataoutput.files = 'air_v1.10';
pipe_air.dataoutput.namerule = 'standard';
% pipe for noneliear calibration
pipe_nl = struct();
pipe_nl.Log2 = struct();                                % log2
pipe_nl.Air = struct();                                 % air correcion (don't define .corr)
pipe_nl.Badchannel.badindex = badchannelindex;          % bad channel
pipe_nl.Offfocal = struct();                            % off-focal corr
pipe_nl.Offfocal.offintensity = 0.005;
pipe_nl.Offfocal.offwidth = 65;
pipe_nl.Offfocal.offedge = 0.6;                         % hard-code parameters of off-focal, only for 120KV, head bowtie!
pipe_nl.Beamharden = struct();                          % beamharden, whose .corr will be replaced by BHcalitable
pipe_nl.Housefield.HCscale = 1000;                      % Housefield
pipe_nl.Databackup_1.dataflow = 'rawdata';
pipe_nl.Databackup_1.index = 1;                         % backup the original data
pipe_nl.Axialrebin.QDO = 0;                             % rebin
pipe_nl.Watergoback.filter.name = 'hann';
pipe_nl.Watergoback.filter.freqscale = 1.2;             % ideal water
% pipe_nl.Watergoback.offfocal = 'deep';
pipe_nl.Watergoback.offfocal = 'weak';
pipe_nl.Inverserebin = struct();                        % inverse rebin
pipe_nl.Databackup_2.dataflow = {'rawdata', 'rawhead'};
pipe_nl.Databackup_2.index = 2;                         % backup the ideal water data
% nl last
pipe_nl_last = struct();
pipe_nl_last.nonlinearcali = struct();
pipe_nl_last.crosstalkcali = struct();
pipe_nl_last.crosstalkcali.Npixelpermod = 16;
pipe_nl_last.crosstalkcali.Nmerge = 8;
pipe_nl_last.dataoutput.files = 'nonlinear, crosstalk';
pipe_nl_last.dataoutput.namerule = 'standard';

% read configure file
configure.system = readcfgfile(system_cfgfile);
configure.protocol = readcfgfile(protocol_cfgfile);
Nseries = configure.protocol.seriesnumber;
% I know the Nseries shall be 2

scanxml = cell(1, Nphantom);
% prepare data
for iph = 1:Nphantom
    % set phantom
    configure.phantom = readcfgfile(phatomfiles{iph});
    % replace namekey
    for i_series = 1:Nseries
        configure.protocol.series{i_series}.namekey = phantoms{iph};
    end
    
    % switch scan method (simulation, real scan or prepared data)
    switch scan_data_method
        case 'simu'
            % do simulation to get the raw data
            scanxml{iph} = CTsimulation(configure);
        case 'real'
            % do real scan
            configure = configureclean(configure);
            % system configure
            SYS = systemconfigure(configure.system);
            SYS = systemprepare(SYS);
            % put phantom
            fprintf('put phantom %s... ', phantoms{iph});
            % to put the phantom phantoms{iph} on real CT
            % TBC
            pause();
            % JUST A SAMPLE
            % loop the series
            scanxml{iph} = cell(1, Nseries);
            for i_series = 1:Nseries
                % I know the series 1,2 should be body and head bowtie
                SYS.protocol = protocolconfigure(configure.protocol.series{i_series});
                SYS.protocol.series_index = i_series;
                % load protocol (to SYS)
                SYS = loadprotocol(SYS);
                % reconxml
                [scanprm, scanxml{iph}{i_series}] = reconxmloutput(SYS);
                % scan data
                fprintf('scan data... ');
                % use the scanprm{iw}.protocol to scan data on real CT
                % TBC
                pause();
                % JUST A SAMPLE
            end
        case 'prep'
            % prepared data
            % data has been prepared
            scanxml{iph} = cell(1, Nseries);
            % if we have done a simulation or real scan, here we can load the scanxml.
        otherwise
            error('Unknown method %s', scan_data_method);
    end
end

% get calixml of step2
% phantoms to use in this step
phantomtouse = [1  3  5]; 
Nphatouse = length(phantomtouse);
% reload configure
configure.system = readcfgfile(system_cfgfile);
configure.protocol = readcfgfile(protocol_cfgfile);
configure = configureclean(configure);
% add output.corrtable
configure.system.output.corrtable = 'air_v1.10, nonlinear';
% system configure
SYS = systemconfigure(configure.system);
SYS = systemprepare(SYS);
% ini calixml
nlcalixml = struct();
% loop the series (bowtie)
for i_series = 1:Nseries
    % I know the series 1,2 should be body and head bowtie
    SYS.protocol = protocolconfigure(configure.protocol.series{i_series});
    SYS.protocol.series_index = i_series;    
    % load protocol (to SYS)
    SYS = loadprotocol(SYS);
    % the bowtie is
    bowtie = lower(SYS.protocol.bowtie);
    % KVs
    Nw = SYS.source.Wnumber;
    
    % ini calixml of the bowtie
    nlcalixml.(bowtie) = cell(1, Nw);
    tmp = struct();     tmp.recon = cell(1, Nphatouse);
    nlcalixml.(bowtie)(:) = {tmp};
    % loop phantoms
    for i_touse = 1:Nphatouse
        iph = phantomtouse(i_touse);
        if ~isempty(scanxml{iph}{i_series})
            % load scan xml
            scanxml_ii = readcfgfile(scanxml{iph}{i_series});
            if ~iscell(scanxml_ii.recon)
                % to cell
                scanxml_ii.recon = {scanxml_ii.recon};
            end
            for iw = 1:Nw
                % basic
                nlcalixml.(bowtie){iw}.recon{i_touse} = scanxml_ii.recon{iw};
                % output path
                nlcalixml.(bowtie){iw}.recon{i_touse}.outputpath = calioutputpath;
            end
        else
            % prepared data?
            % generate recon configure by SYS
            scanxml_ii.recon = reconxmloutput(SYS, 0);
            for iw = 1:Nw
                if isfield(rawdata_file, bowtie) && ~isempty(rawdata_file.(bowtie){iw})
                    % basic
                    nlcalixml.(bowtie){iw}.recon{i_touse} = scanxml_ii.recon{iw};
                    % rawdata
                    nlcalixml.(bowtie){iw}.recon{i_touse}.rawdata = rawdata_file.(bowtie){iw}{iph};
                    % output path
                    nlcalixml.(bowtie){iw}.recon{i_touse}.outputpath = calioutputpath;
                else
                    % delete
                    nlcalixml.(bowtie){iw}.recon{i_touse} = [];
                end
            end
        end
        % replace pipe
        for iw = 1:Nw
            if ~isempty(nlcalixml.(bowtie){iw}.recon{i_touse})
                if iph==1
                    % air
                    nlcalixml.(bowtie){iw}.recon{i_touse}.pipe = pipe_air;
                else
                    % water
                    nlcalixml.(bowtie){iw}.recon{i_touse}.pipe = pipe_nl;
                    % Beamharden.corr
                    nlcalixml.(bowtie){iw}.recon{i_touse}.pipe.Beamharden.corr = BHcalitable.(bowtie){iw};
                    % backup index
                    nlcalixml.(bowtie){iw}.recon{i_touse}.pipe.Databackup_1.index = ...
                        nlcalixml.(bowtie){iw}.recon{i_touse}.pipe.Databackup_1.index + (i_touse-2)*2;
                    nlcalixml.(bowtie){iw}.recon{i_touse}.pipe.Databackup_2.index = ...
                        nlcalixml.(bowtie){iw}.recon{i_touse}.pipe.Databackup_2.index + (i_touse-2)*2;
                    % last one
                    if i_touse==Nphatouse
                        nlcalixml.(bowtie){iw}.recon{i_touse}.pipe = ...
                            structmerge(nlcalixml.(bowtie){iw}.recon{i_touse}.pipe, pipe_nl_last, 0, 0);
                    end
                end
            end
        end
    end
end

% ini the return (corr file name)
calitable = struct();
calitable.air = struct();
calitable.nonlinear = struct();
calitable.crosstalk = struct();
% copy the beamharden
calitable.beamharden = BHcalitable;

% loop (bowtie) and KV to get the non-linear calibration tables #1
bowties_cali = fieldnames(nlcalixml);
for ibow = 1:length(bowties_cali)
    % bowtie
    bowtie = bowties_cali{ibow};
    % ini 
    calitable.air.(bowtie) = cell(1, Nw);
    calitable.nonlinear.(bowtie) = cell(1, Nw);
    calitable.crosstalk.(bowtie) = cell(1, Nw);
    
    % Nw (KV)
    Nw = length(nlcalixml.(bowtie));
    for iw = 1:Nw
        if isempty(nlcalixml.(bowtie){iw}.recon{1})
            continue
        end
        [~, dataflow, prmflow] = CTrecon(nlcalixml.(bowtie){iw});
        % or replace it by 
        % load('E:\data\rawdata\bhtest\flow\flow_0213.mat');
        % to debug
        
        % record the .corr files name
        if isfield(prmflow.output, 'aircorr')
            calitable.air.(bowtie){iw} = prmflow.output.aircorr;
        end
        if isfield(prmflow.output, 'nonlinearcorr')
            calitable.nonlinear.(bowtie){iw} = prmflow.output.nonlinearcorr;
        end
        if isfield(prmflow.output, 'crosstalkcorr')
            calitable.crosstalk.(bowtie){iw} = prmflow.output.crosstalkcorr;
        end
    end
end

output_file = fullfile(calioutputpath, 'nlcalitable_step2.mat');
save(output_file, '-struct', 'calitable');

