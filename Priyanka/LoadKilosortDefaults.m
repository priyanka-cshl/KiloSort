function [handles] = LoadKilosortDefaults(handles, Username)

addpath(genpath('/opt/KiloSort/')) % path to kilosort folder
addpath(genpath('/opt/npy-matlab/')) % path to npy-matlab scripts

% default settings
handles.FilePaths.Data(1) = {'/mnt/grid-hs/pgupta/EphysData'}; % Root storage
handles.FilePaths.Data(2) = {'PCX4'}; % local read/write folder
handles.FilePaths.Data(3) = {'/mnt/data/Sorted/'}; % local read/write folder
handles.YourConfigFile = '/opt/KiloSort/StandardConfig_Albeanu.m';

% spike detection settings
handles.init_from_data = 0; % generate template spikes from data
handles.spike_det_settings.Data(1) = 2; % x, number of clusters - x times more than Nchan
handles.spike_det_settings.Data(2) = -4; % spike threshold in standard deviations (4)
handles.filter2binary.Value = 1; % default is to save bandpassed filtered data locally to binary file
handles.computeCAR.Value = 1; % default is to subtract the Common average reference
handles.IgnoreChannels.String = ''; % channels that shouldn't be included in computing CAR

% recording settings
handles.recording_settings.Data(1) = 64; % no. of spike channels saved
handles.InactiveChannels.String = ''; % channels that shouldn't be loaded

% overwrite settings as per need
switch Username
    case {'K4'}
        handles.FilePaths.Data(1) = {'/mnt/data/Priyanka'}; % Root storage
        handles.FilePaths.Data(2) = {'K4'}; % Animal Name
        handles.IgnoreChannels.String = mat2str([22 26 41 42 43 45 46 49 50 53 54 55 56 59 60]);
    case {'PCX1','PCX3','PCX4','PCX5'}
        handles.FilePaths.Data(1) = {'/mnt/grid-hs/pgupta/EphysData'};
        handles.FilePaths.Data(2) = {Username};
        handles.recording_settings.Data(1) = 64;
        handles.InactiveChannels.String = mat2str([]);
        handles.IgnoreChannels.String = mat2str([]);
    case {'O5','O3'}
        handles.FilePaths.Data(1) = {'/mnt/grid-hs/mdussauz/ephysdata/lever_task/BatchO'};
        handles.FilePaths.Data(2) = {Username};
        handles.recording_settings.Data(1) = 64;
        handles.InactiveChannels.String = mat2str(9:32);
        handles.IgnoreChannels.String = mat2str([]);
    case {'O2','O1'}
        handles.FilePaths.Data(1) = {'/mnt/grid-hs/mdussauz/ephysdata/lever_task/BatchO'};
        handles.FilePaths.Data(2) = {Username};
        handles.recording_settings.Data(1) = 64;
        handles.InactiveChannels.String = mat2str(1:32);
        handles.IgnoreChannels.String = mat2str([]);
    case {'MO1'}
        handles.FilePaths.Data(1) = {'/mnt/data/Priyanka'};
        handles.FilePaths.Data(2) = {'MO1'};
        handles.recording_settings.Data(1) = 32;
        handles.InactiveChannels.String = mat2str([]);
        handles.IgnoreChannels.String = mat2str([]);
end
end