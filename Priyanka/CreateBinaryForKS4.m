function [] = CreateBinaryForKS4(mousename)
handles = [];
handles = LoadKilosortDefaults(handles, mousename);
handles.FilePaths.Data(1) = {'/mnt/storage/Raw'};
handles.FilePaths.Data(1) = {'/mnt/data/cid_raw'};
% some settings from kilosort gui
ops.saveAUXbinaryfile = 1;
ops.ZeroNoisyChans = 1;
handles.FilePaths.Data(3) = {'/mnt/storage/Sorted/'}; % local read/write folder

% get the folder
X = uigetfile_n_dir(char(fullfile(handles.FilePaths.Data(1),handles.FilePaths.Data(2))),...
    'Select experimental session folder');

if ~isempty (X)
    for i = 1:size(X,2)
        M =  regexp(char(X(i)),filesep,'split');
        handles.db(1).expts(i) = M(end);
    end
end

rootpath = char(handles.FilePaths.Data(1));
%clear rootpath datapath configpath
uniquesessions = length(handles.db(1).expts);

for j = 1:uniquesessions % for each file within the session

    datapath = fullfile(char(handles.FilePaths.Data(2)),char(handles.db(1).expts(j)));
    localpath = fullfile(char(handles.FilePaths.Data(3)),...
        char(handles.FilePaths.Data(2)),...
        char(handles.db(1).expts(j)));

    run(handles.YourConfigFile);


    %% some channel settings
    % to flag out aux channels from ephys channels
    ops.ActiveChannels = 1:(handles.recording_settings.Data(1) - handles.recording_settings.Data(2));

    % to reorder channels if record node was before the channelmap node
    if ~isempty(handles.ReorderChannels)
        ops.ActiveChannels = handles.ReorderChannels;
    end

    % if useless channels were recorded - skip them from the binary file
    [~,notConnected] = ismember(eval(handles.InactiveChannels.String), ops.ActiveChannels);
    ops.ActiveChannels(notConnected) = [];
    % not sure the inactive channel works for batch Q

    % just parse some info to ops the way kilosort likes it
    ops.Nchan = numel(ops.ActiveChannels); % number of active channels
    ops.NchanTOT = ops.Nchan;  % we don't use this

    % create a list of valid channels - account for the unloaded channels
    ops.DeadChans = eval(handles.IgnoreChannels.String);
    [~,chans2omit] = ismember(ops.DeadChans, ops.ActiveChannels);
    ops.ValidChannels = true(ops.Nchan,1);
    ops.ValidChannels(chans2omit(chans2omit~=0)) = false;

    ops.ReFilter = handles.filter2binary.Value;
    ops.CAR = handles.computeCAR.Value;


    ops.datatype = 'flatbinary'; %'opendat';
    ops.Nchanbinary = handles.recording_settings.Data(1);

    [binarypath, binaryfile, ext] = fileparts(ops.fbinary);

    hasBinary = 0;
    % check if the binary file has already been created
    if exist(fullfile(handles.ServerPath,datapath)) || exist(fullfile(binarypath,'mybinaryfile.dat'))
        reply = input('A binary file for this session already exists. \nDo you want to overwrite? Y/N [Y]: ','s');
        if ~strcmp(reply,'Y')
            hasBinary = 1;
        end
    end

    if ~hasBinary
        if ~exist(binarypath,'dir')
            mkdir(binarypath);
            fileattrib(binarypath,'+w','a');
        end

        disp('');
        disp(['processing session: ',fullfile(rootpath,datapath)]);
        tic; % start timer
        if ops.GPU
            gpuDevice(1); % initialize GPU (will erase any existing GPU arrays)
        end
        if strcmp(ops.datatype , 'flatbinary')
            ops = processOEPSBinary(ops);  % for batchQ: filters and rewrites OEPS binary file to KS binary (only ephys channels), ...
        end

        % change permissions
        command = ['chmod -R 777 ',binarypath];
        system(command);
    end
end

end