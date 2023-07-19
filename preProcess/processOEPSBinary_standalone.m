function [] = processOEPSBinary_standalone(OEPSfolder, BinaryFolder, varargin)

%% parse input arguments
narginchk(1,inf)
params = inputParser;
params.CaseSensitive = false;

params.addParameter('badchans', [], @(x) isnumeric(x));
params.addParameter('ignoremode',  2, @(x) isnumeric(x));
params.addParameter('filter', true, @(x) islogical(x) || x==0 || x==1);
params.addParameter('CAR', true, @(x) islogical(x) || x==0 || x==1);
params.addParameter('saveAUX', false, @(x) islogical(x) || x==0 || x==1);
params.addParameter('saveAUXBinary', false, @(x) islogical(x) || x==0 || x==1);

% extract values from the inputParser
params.parse(varargin{:});
badchans          = params.Results.badchans; % channel ids of noisy or shorted channels - to be excluded from the CAR
ignoremode        = params.Results.ignoremode; % what to do with bad channels - 0: nothing, 1: zero them, 2: delete them
dofilter          = params.Results.filter;
subtractCAR      = params.Results.CAR;
saveAUX           = params.Results.saveAUX;
saveAUXbinaryfile = params.Results.saveAUXBinary;

tic
%% read the open ephys flat binary file
addpath(genpath('/opt/open-ephys-matlab-tools')) % path to new open ephys data handling scripts
session = Session(OEPSfolder(1,:));

%% settings
fs = session.recordNodes{1}.recordings{1}.info.continuous.sample_rate; % OEPS sampling rate
NT = session.recordNodes{1}.recordings{1}.info.continuous.num_channels; % total num of channels
ephysChans = zeros(NT,1);
for i = 1:NT
    ephysChans(i,1) = strcmp('uV',session.recordNodes{1}.recordings{1}.info.continuous.channels(i).units);
end

ntbuff      = 64; % from kilosort: % samples of symmetrical buffer for whitening and spike detection
NTbuff      = NT + 4*ntbuff;
auxchans    = numel(find(~ephysChans));
binarychans = 1:(NT - auxchans);
ValidChannels = ~ismember(binarychans, badchans);

% for band pass filtering
fslow   = 6000;
fshigh  = 300;
[b, a] = butter(3, [fshigh/fs, fslow/fs]*2, 'bandpass');

% binary file
if ~exist(BinaryFolder,'dir')
    mkdir(BinaryFolder);
    fileattrib(BinaryFolder,'+w','a');
end

fname       = fullfile(BinaryFolder,'mybinaryfile.dat');  
fidout      = fopen(fname, 'w');
fid_aux_out = fopen(fullfile(BinaryFolder,'myauxfile.dat'), 'w');

ibatch = 0; nsamps = 0; TrailingSamps = 0;
for q = 1:size(OEPSfolder,1)
    
    if q>1
        session = Session(OEPSfolder(q,:));
    end
    TotalSamples = size(session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps,1);
    % for saving info about Files and writing the aux file
    Files = [];
    Files.Samples(q) = TotalSamples;
    Files.StartTimestamp(q) = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps(1);
    
    if saveAUX
        % extra step - to save in the same folder - TTL data
        Events = session.recordNodes{1}.recordings{1}.ttlEvents('Acquisition_Board-100.Rhythm Data');
        TTLs.data            = Events.channel;
        TTLs.timestamps      = Events.timestamp;
        TTLs.info.eventId    = Events.state;
        
        % to adjust for clock offset between open ephys and kilosort
        TTLs.offset = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps(1);
        
        save (fullfile(BinaryFolder,['myTTLfile','_',num2str(q),'.mat']),'TTLs');
    end

    while 1
        ibatch = ibatch + 1;
        offset = NTbuff * (ibatch - 1) - TrailingSamps;
        
        if offset>=TotalSamples
            break;
        end
        
        if (offset + NTbuff) <= TotalSamples
            if (q > 1) && (ibatch == 1)
                samples = horzcat(samples, ...
                    session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').samples(:,1:(NTbuff-nsampcurr)) );
            else
                samples = ...
                    session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').samples(:,offset+(1:NTbuff));
            end
        else
            samples = ...
                session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').samples(:,offset+1:TotalSamples);
            nsampcurr = size(samples,2);
            TrailingSamps = nsampcurr;
            if q<size(OEPSfolder,1)
                ibatch = 0;
                break;
            else
                samples(:, nsampcurr+1:NTbuff) = repmat(samples(:,nsampcurr), 1, NTbuff-nsampcurr);
            end
        end
        
        if saveAUXbinaryfile
            % write the aux data to auxbinaryfile
            fwrite(fid_aux_out, samples(end-auxchans+1:end,:), 'int16');
        end
        % delete the aux channels
        samples(end-auxchans+1:end,:) = [];
        
        samples = samples';
        
        if dofilter
            % filter the data
            samples = filter(b,a,samples);
            samples = flipud(samples);
            samples = filter(b,a,samples);
            samples = flipud(samples);
        end
        
        if subtractCAR
            samples = samples - mean(samples(:,find(ValidChannels)),2);
        end
        
        samples = samples';
        
        switch ignoremode
            case 1
                % make noisy channels zero
                samples(find(~ValidChannels),:) = 0;
                
                % write to binary file
                fwrite(fidout, samples, 'int16');
                nsamps = nsamps + size(samples,2);
            case 2
                % delete noisy channels before writing
                % write to binary file
                fwrite(fidout, samples(find(ValidChannels),:), 'int16');
                nsamps = nsamps + size(samples(find(ValidChannels),:),2);
            otherwise
                % write to binary file
                fwrite(fidout, samples, 'int16');
                nsamps = nsamps + size(samples,2);
        end
                    
    end
end
        
fclose(fidout);

% outputs for kiloSort
% ops.nSamplesBlocks(k) = nsamps;
% ops.Nchanbinary = numel(binaryChans) - (ignoremode==2)*numel(find(~ValidChannels));

Files.name = OEPSfolder;
Files.Channels(1:2) = numel(binarychans);
if ignoremode == 2
    Files.Channels(2) = numel(binarychans) - numel(find(~ValidChannels));
else
    ValidChannels = ones(numel(ValidChannels),1);
end

% make the channel map
createChannelMapBatchQ_v2(fullfile(BinaryFolder,'chanMap.mat'),ValidChannels,fs);
save (fullfile(BinaryFolder,'SessionDetails.mat'),'Files');

% change permissions
command = ['chmod -R 777 ',BinaryFolder];
system(command);

toc