function ops = processOEPSNonBinary(ops)

% for band pass filtering
if isfield(ops,'fslow')&&ops.fslow<ops.fs/2
    [b, a] = butter(3, [ops.fshigh/ops.fs,ops.fslow/ops.fs]*2, 'bandpass');
else
    [b, a] = butter(3, ops.fshigh/ops.fs*2, 'high');
end

fname       = ops.fbinary;  %fullfile(ops.root, sprintf('%s.dat', ops.fbinary)); 
fidout      = fopen(fname, 'w');
fid_aux_out = fopen(fullfile(fileparts(ops.fbinary),'myauxfile.dat'), 'w');

% NT          = ops.NT ; 
% NTbuff      = NT + 4*ops.ntbuff;
% auxchans    = ops.Nchanbinary - ops.Nchan; % this won't work numel(dir(fullfile(ops.root, '*.continuous')))
% ibatch = 0;
% nsamps = 0;
% TotalSamples = 0;
nBlocks = 1;
% TrailingSamps = 0;
% 
% ValidChannels = ops.ValidChannels(1:ops.Nchan);

Files = [];
nSamples    = 1024;  % fixed to 1024 for now!
%%   
tic
for k = 1:nBlocks

    if ops.saveAUXbinaryfile
        addpath(genpath('/opt/open-ephys-analysis-tools')) % path to new open ephys data handling scripts
        filename = ops.RecordingInfo.eventFiles{1};
        [TTLs.data, TTLs.timestamps, TTLs.info] = load_open_ephys_data(filename); % data has channel IDs
        startTS = double(ops.RecordingInfo.startSample)/ops.RecordingInfo.sampleRate;

        % adjust for clock offset between open ephys and kilosort
        TTLs.offset = startTS;
        Files.StartTimestamp(nBlocks) = startTS;
        Files.StartSample(nBlocks) = ops.RecordingInfo.startSample;
        save (fullfile(fileparts(ops.fbinary),['myTTLfile','_',num2str(k),'.mat']),'TTLs');
        %
        totalchans = ops.Nchanbinary;
        auxchans = ops.NchanAux;
    else
        totalchans = ops.Nchanbinary - ops.NchanAux;
    end
    
    for j = 1:numel(ops.RecordingInfo.ephysFiles)
        fid{j} = fopen(fullfile(ops.RecordingFolder, ops.RecordingInfo.ephysFiles{j}));
        % discard header information
        fseek(fid{j}, 1024, 0);
    end
    for k = 1:numel(ops.RecordingInfo.auxFiles)
        fid{j+k} = fopen(fullfile(ops.RecordingFolder, ops.RecordingInfo.auxFiles{k}));
        % discard header information
        fseek(fid{j+k}, 1024, 0);
    end

    nsamps = 0;
    flag = 1;
    while 1
        samples = zeros(nSamples * 1000, totalchans, 'int16');
        for j = 1:numel(fid)
            collectSamps    = zeros(nSamples * 1000, 1, 'int16');
            
            rawData         = fread(fid{j}, 1000 * (nSamples + 6), '1030*int16', 10, 'b');

            nbatches        = ceil(numel(rawData)/(nSamples+6));
            for s = 1:nbatches
                rawSamps = rawData((s-1) * (nSamples + 6) +6+ [1:nSamples]);
                collectSamps((s-1)*nSamples + [1:nSamples]) = rawSamps;
            end
            samples(:,j)         = collectSamps;
        end
        
        if nbatches<1000
            flag = 0;
        end
        if flag==0
            samples = samples(1:s*nSamples, :);
        end

        if ops.saveAUXbinaryfile
            % write the aux data to auxbinaryfile
            fwrite(fid_aux_out, samples(:,end-auxchans+1:end)', 'int16');

            % delete the aux channels
            samples(:,end-auxchans+1:end) = [];
        end
        
        if ops.ReFilter
            % filter the data
            samples = filter(b,a,samples);
            samples = flipud(samples);
            samples = filter(b,a,samples);
            samples = flipud(samples);
            if ops.CAR
                samples = samples - mean(samples(:,find(ops.ValidChannels)),2);
            end

            if ops.ZeroNoisyChans
                % make noisy channels zero
                samples(:,find(~ops.ValidChannels)) = 0;
            end
        end
        
        samples         = samples';
        
        % write to binary file
        fwrite(fidout, samples, 'int16');

        nsamps = nsamps + size(samples,2);
        
        if flag==0
            break;
        end
    end
    ops.nSamplesBlocks(k) = nsamps;
    
    for j = 1:ops.Nchan
       fclose(fid{j}); 
    end

    Files.Samples(nBlocks) = nsamps; %TotalSamples;
    %Files.StartTimestamp(nBlocks) = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps(1)
    
end
    
fclose(fidout);

Files.name = ops.RecordingFolder;
Files.AllSettings = ops;
save (fullfile(fileparts(ops.fbinary),'SessionDetails.mat'),'Files');

toc