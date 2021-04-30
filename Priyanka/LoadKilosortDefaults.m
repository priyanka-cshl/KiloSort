function [handles] = LoadKilosortDefaults(handles, Username)
% default settings
handles.FilePaths.Data(1) = {'/mnt/analysis/'}; % Root storage
handles.FilePaths.Data(2) = {'N8/'}; % local read/write folder
handles.init_from_data.Value = 0;
handles.spike_det_settings.Data(2) = -4; % spike threshold in standard deviations (4)
handles.spike_det_settings.Data(1) = 32; % number of clusters to use (2-4 times more than Nchan, should be a multiple of 32)
handles.filter2binary.Value = 0;
handles.IgnoreChannels.String = '';
handles.YourConfigFile = 'StandardConfig_PANQI.m';

% overwrite settings as per need
switch Username
    case {'standard'}
    case {'PG32'}
        handles.FilePaths.Data(1) = {'/mnt/data/Priyanka'}; % Root storage
        handles.FilePaths.Data(2) = {'J6/'}; % local read/write folder
        handles.spike_det_settings.Data(1) = 64;
        handles.filter2binary.Value = 1;
        handles.YourConfigFile = 'StandardConfig_MARIE_32.m';
    case {'PG64'}
        handles.FilePaths.Data(1) = {'/mnt/data/Priyanka'}; % Root storage
        handles.FilePaths.Data(2) = {'J4/'}; % local read/write folder
        handles.spike_det_settings.Data(1) = 256;
        handles.filter2binary.Value = 1;
        handles.YourConfigFile = 'StandardConfig_PG64.m';
    case {'PG_APC'}
        handles.FilePaths.Data(1) = {'/mnt/data/Priyanka'}; % Root storage
        handles.FilePaths.Data(2) = {'PCX1/'}; % local read/write folder
        handles.spike_det_settings.Data(1) = 128;
        handles.filter2binary.Value = 1;
        handles.YourConfigFile = 'StandardConfig_PG64.m';
    case {'AZ'}
    case {'K4'}
        handles.FilePaths.Data(1) = {'/mnt/data/Priyanka'}; % Root storage
        handles.FilePaths.Data(2) = {'K4/'}; % local read/write folder
        handles.spike_det_settings.Data(1) = 256;
        handles.filter2binary.Value = 1;
        handles.YourConfigFile = 'StandardConfig_PG64_K4.m';
        handles.IgnoreChannels.String = '22 26 41 42 43 45 46 49 50 53 54 55 56 59 60';
        
    case {'K1'}
    case {'MD'}
        handles.FilePaths.Data(1) = {'/mnt/data/Marie'}; % Root storage
        handles.FilePaths.Data(2) = {'N5/'}; % local read/write folder
        handles.YourConfigFile = 'StandardConfig_MARIE_32.m';
        handles.IgnoreChannels.String = '';
        
    case {'MD_Corsica'}
        handles.FilePaths.Data(1) = {'/mnt/data'}; % Root storage
        handles.FilePaths.Data(2) = {'N5/'}; % local read/write folder
        handles.YourConfigFile = 'StandardConfig_MARIE_32.m';
        handles.IgnoreChannels.String = '';
end
end