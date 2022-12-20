function ops = convertOEPSFlatBinaryToKSBinary_v2(ops)

% for band pass filtering
if isfield(ops,'fslow')&&ops.fslow<ops.fs/2
    [b, a] = butter(3, [ops.fshigh/ops.fs,ops.fslow/ops.fs]*2, 'bandpass');
else
    [b, a] = butter(3, ops.fshigh/ops.fs*2, 'high');
end

fname       = ops.fbinary;  
fidout      = fopen(fname, 'w');

% read the open ephys flat binary file
session = Session(fileparts(ops.root));
TotalSamples = size(session.recordNodes{1}.recordings{1}.continuous('Acquisition_Board-100.Rhythm Data').timestamps,1);

fid         = fopen(ops.rawbinary, 'r');
NchanTOT    = ops.Nchanbinary;
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

% hack
ops.Nchanbinary = ops.Nchan;

toc