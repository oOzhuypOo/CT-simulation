% a projection test script
clear;
addpath(genpath('../'));

configure.system = systemcfgsample();
configure.phantom = phantomcfgsample();
configure.protocal = protocalcfgsample();

% output sample xmls
% root = [];
% root.configure = configure;
% struct2xml(root, 'D:\matlab\CTsimulation\system\mod\sample_configure.xml');
root = [];
root.system = configure.system;
struct2xml(root, 'D:\matlab\CTsimulation\system\mod\sample_system.xml');
root = [];
root.protocal = configure.protocal;
struct2xml(root, 'D:\matlab\CTsimulation\system\mod\sample_protocal.xml');

% clean configure
configure = configureclean(configure);

% output sample xmls 2
root = [];
root.configure = configure;
struct2xml(root, 'D:\matlab\CTsimulation\system\mod\sample_output_configure.xml');

% get SYS from system configure
SYS = systemconfigure(configure.system);
% phantom
SYS.phantom = phantomconfigure(configure.phantom);

% simulation prepare (load material)
SYS = systemprepare(SYS);

% loop the series
Nseries = configure.protocal.seriesnumber;
for i_series = 1:Nseries
    % to play i-th series
    % load protocal
    SYS.protocal = configure.protocal.series{i_series};
    SYS.protocal.series_index = i_series;
    SYS = loadprotocal(SYS);
    
end

