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

NT          = ops.NT ;
NTbuff      = NT + 4*ops.ntbuff;
auxchans    = ops.Nchanbinary - ops.Nchan;
ibatch = 0;
nsamps = 0;
TotalSamples = 0;
nBlocks = 1;
TrailingSamps = 0;

ValidChannels = ops.ValidChannels(1:ops.Nchan);

Files = [];

tic
for k = 1:nBlocks
    
    for q = 1:size(ops.root,1)
        
        % read the open ephys flat binary file
        session = Session(ops.root(q,:));
        TotalSamples = size(session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps,1);
        Files.Samples(q) = TotalSamples;
        Files.StartTimestamp(q) = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps(1);
        
        if ops.saveAUXbinaryfile
            % extra step - to save in the same folder - TTL data
            Events = session.recordNodes{1}.recordings{1}.ttlEvents('Acquisition_Board-100.Rhythm Data');
            TTLs.data            = Events.channel;
            TTLs.timestamps      = Events.timestamp;
            TTLs.info.eventId    = Events.state;
            
            % to adjust for clock offset between open ephys and kilosort
            TTLs.offset = session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps(1);
            
            save (fullfile(fileparts(ops.fbinary),['myTTLfile','_',num2str(q),'.mat']),'TTLs');
            %
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
                if q<size(ops.root,1)
                    ibatch = 0;
                    break;
                else
                    samples(:, nsampcurr+1:NTbuff) = repmat(samples(:,nsampcurr), 1, NTbuff-nsampcurr);
                end
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
        
    end
    ops.nSamplesBlocks(k) = nsamps;
end

fclose(fidout);

Files.name = ops.root;
save (fullfile(fileparts(ops.fbinary),'SessionDetails.mat'),'Files');

% hack
ops.Nchanbinary = ops.Nchan;

toc