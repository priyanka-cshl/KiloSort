function ops = processOEPSBinary(ops)

% for band pass filtering
if isfield(ops,'fslow')&&ops.fslow<ops.fs/2
    [b, a] = butter(3, [ops.fshigh/ops.fs,ops.fslow/ops.fs]*2, 'bandpass');
else
    [b, a] = butter(3, ops.fshigh/ops.fs*2, 'high');
end

fname       = ops.fbinary;  
fidout      = fopen(fname, 'w');
fid_aux_out = fopen(fullfile(fileparts(ops.fbinary),'myauxfile.dat'), 'w');

% read the open ephys flat binary file
session = Session(ops.root);
TotalSamples = size(session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps,1);

NT          = ops.NT ;
NTbuff      = NT + 4*ops.ntbuff;
auxchans    = ops.Nchanbinary - ops.Nchan;
ibatch = 0;
nsamps = 0;
nBlocks = 1;

ValidChannels = ops.ValidChannels(1:ops.Nchan);

tic
for k = 1:nBlocks
    while 1
        ibatch = ibatch + 1;
        offset = NTbuff * (ibatch - 1);
        if offset>=TotalSamples
            break;
        end
        if (offset + NTbuff) <= TotalSamples 
            samples = ...
                session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').samples(:,offset+(1:NTbuff));
        else
            samples = ...
                session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').samples(:,offset+1:TotalSamples);
            nsampcurr = size(samples,2);
            samples(:, nsampcurr+1:NTbuff) = repmat(samples(:,nsampcurr), 1, NTbuff-nsampcurr);
        end
        
        if ops.saveAUXbinaryfile
            % write the aux data to auxbinaryfile
            fwrite(fid_aux_out, samples(end-auxchans+1:end,:), 'int16');
        end
        % delete the aux channels
        samples(end-auxchans+1:end,:) = [];
        
        samples = samples';

        % reorder the channels
        samples = samples(:,ops.ActiveChannels);
        
        if ops.ReFilter
            % filter the data
            samples = filter(b,a,samples);
            samples = flipud(samples);
            samples = filter(b,a,samples);
            samples = flipud(samples);
            if ops.CAR
                samples = samples - mean(samples(:,find(ValidChannels)),2);
            end
            % make noisy channels zero
            samples(:,find(~ValidChannels)) = 0;
        end
        
        samples         = samples';
        
        % write to binary file
        fwrite(fidout, samples, 'int16');
        
        nsamps = nsamps + size(samples,2);
        
    end
    ops.nSamplesBlocks(k) = nsamps;
end

fclose(fidout);

if ops.saveAUXbinaryfile
    % extra step - to save in the same folder - TTL data
    Events = session.recordNodes{1}.recordings{1}.ttlEvents('Acquisition_Board-100.Rhythm Data');
    TTLs.data            = Events.channel;
    TTLs.timestamps      = Events.timestamp;
    TTLs.info.eventId    = Events.state;
    
    % to adjust for clock offset between open ephys and kilosort
    TTLs.offset = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps(1);
    
    save (fullfile(fileparts(ops.fbinary),'myTTLfile.mat'),'TTLs');
    %
end

% hack
ops.Nchanbinary = ops.Nchan;

toc