% default options are in parenthesis after the comment

% addpath(genpath('/home/pgupta/Desktop/Code/KiloSort/')) % path to kilosort folder
% addpath(genpath('/home/pgupta/Desktop/Code/npy-matlab/')) % path to npy-matlab scripts
% pathToYourConfigFile = '/home/pgupta/Desktop/Code/KiloSort/configFiles/'; % for this example it's ok to leave this path inside the repo, but for your own config file you *must* put it somewhere else!  
% 
% run(fullfile(pathToYourConfigFile, 'StandardConfig_PANQI.m'))

tic; % start timer
%
if ops.GPU     
    gpuDevice(1); % initialize GPU (will erase any existing GPU arrays)
end

if strcmp(ops.datatype , 'openEphys')
   ops = convertOpenEphysToRawBInaryAnqi(ops);  % convert data, only for OpenEphys
end

%
[rez, DATA, uproj] = preprocessData(ops); % preprocess data and extract spikes for initialization
rez                = fitTemplates(rez, DATA, uproj);  % fit templates iteratively
rez                = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)

% AutoMerge. rez2Phy will use for clusters the new 5th column of st3 if you run this)
%     rez = merge_posthoc2(rez);

% save matlab results file
save(fullfile(ops.root,  'rez.mat'), 'rez', '-v7.3');

% save python results file for Phy
rezToPhy(rez, ops.root);

% remove temporary file
delete(ops.fproc);
%%
