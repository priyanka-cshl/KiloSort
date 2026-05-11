
tic; % start timer
if ops.GPU     
    gpuDevice(1); % initialize GPU (will erase any existing GPU arrays)
end

% get recording settings
RecordingFolder = dir(fullfile(ops.root(1,:),'Record*'));
if isempty(RecordingFolder)
    % check if data is directly inside the main folder
    if ~isempty(dir(fullfile(ops.root(1,:),'*.continuous')))
        ops.RecordingFolder = fullfile(ops.root(1,:));
    end
else
    ops.RecordingFolder = fullfile(RecordingFolder.folder,RecordingFolder.name);
end
ops.RecordingInfo = getRecordingInfo(ops.RecordingFolder);
switch ops.RecordingInfo.format
    case 'OpenEphys'
        if ops.Nchan == numel(ops.RecordingInfo.ephysFiles) && ops.RecordingInfo.nAux == handles.recording_settings.Data(2)
            ops = processOEPSNonBinary(ops);
        elseif ops.Nchan + numel(ops.SkippedChannels) == numel(ops.RecordingInfo.ephysFiles) && ...
                ops.RecordingInfo.nAux == handles.recording_settings.Data(2)
            ops = processOEPSNonBinary(ops);
        else
            keyboard;
        end
    case 'Binary'
        if ops.Nchan == numel(ops.RecordingInfo.ephysFiles) && ops.RecordingInfo.nAux == handles.recording_settings.Data(2)
            ops = processOEPSBinary(ops);
        else
            keyboard;
        end
    otherwise
        keyboard;
end

createChannelMapBatchQ; % make a temporary chanel map for sorting accounting for which channels are loaded etc

if ~ops.onlybinary
    
    ops.Nchanbinary = ops.Nchan;

    [rez, DATA, uproj] = preprocessData_Albeanu(ops); % preprocess data and extract spikes for initialization
    rez                = fitTemplates(rez, DATA, uproj);  % fit templates iteratively
    rez                = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)

    % AutoMerge. rez2Phy will use for clusters the new 5th column of st3 if you run this)
    %     rez = merge_posthoc2(rez);

    % save matlab results file
    save(fullfile(localpath,  'rez.mat'), 'rez', '-v7.3');

    % save python results file for Phy
    rezToPhy(rez, localpath);

    % remove temporary file
    delete(ops.fproc);
end
%%
