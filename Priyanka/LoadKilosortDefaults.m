function [handles] = LoadKilosortDefaults(handles, Username)
% default settings
handles.FilePaths.Data(1) = {'/mnt/analysis/'}; % Root storage
handles.FilePaths.Data(2) = {'N8/'}; % local read/write folder
handles.init_from_data.Value = 0;
handles.spike_det_settings.Data(2) = -4; % spike threshold in standard deviations (4)
handles.spike_det_settings.Data(1) = 32; % number of clusters to use (2-4 times more than Nchan, should be a multiple of 32)
handles.filter2binary.Value = 0;
handles.YourConfigFile = 'StandardConfig_PANQI.m';

% overwrite settings as per need
switch Username
    case {'standard'}
    case {'PG32'}
    case {'PG64'}
        handles.FilePaths.Data(1) = {'/mnt/data/Priyanka'}; % Root storage
        handles.FilePaths.Data(2) = {'K1/'}; % local read/write folder
        handles.spike_det_settings.Data(1) = 256;
        handles.filter2binary.Value = 1;
        handles.YourConfigFile = 'StandardConfig_PG64.m';

    case {'AZ'}
    case {'K4'}
        handles.FilePaths.Data(1) = {'/mnt/data/Priyanka'}; % Root storage
        handles.FilePaths.Data(2) = {'K4/'}; % local read/write folder
        handles.spike_det_settings.Data(1) = 256;
        handles.filter2binary.Value = 1;
        handles.YourConfigFile = 'StandardConfig_PG64_K4.m';
    case {'K1'}
    case {'MD'}
        handles.FilePaths.Data(1) = {'/mnt/data/Marie'}; % Root storage
        handles.FilePaths.Data(2) = {'N5/'}; % local read/write folder
    case {'MD_Corsica'}
        handles.FilePaths.Data(1) = {'/mnt/data'}; % Root storage
        handles.FilePaths.Data(2) = {'N5/'}; % local read/write folder
end
end