
tic; % start timer
%
if ops.GPU     
    gpuDevice(1); % initialize GPU (will erase any existing GPU arrays)
end

if strcmp(ops.datatype , 'openEphys')
   ops = convertOpenEphysToRawBInaryAlbeanu(ops);  % convert data, only for OpenEphys
end

if strcmp(ops.datatype , 'opendat')
   ops = convertOpenEphysBinaryToRawBinaryAlbeanu(ops);  % convert data, only for OpenEphys
end

if strcmp(ops.datatype , 'flatbinary')
   ops = processOEPSBinary(ops);  % for batchQ: filters and rewrites OEPS binary file to KS binary (only ephys channels), ...
   % also creates an aux binary that contains behavioral data, and creates
   % TTL matrices - later used for alignment with behavior
end

ops.datatype = 'openEphys';
createChannelMapBatchQ; % make a temporary chanel map for sorting accounting for which channels are loaded etc

%
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
%%
