function ops = convertOEPSFlatBinaryToKSBinary(ops)

if isfield(ops,'fslow')&&ops.fslow<ops.fs/2
    [b, a] = butter(3, [ops.fshigh/ops.fs,ops.fslow/ops.fs]*2, 'bandpass');
else
    [b, a] = butter(3, ops.fshigh/ops.fs*2, 'high');
end
%[b,a] = butter(3,2*[300 6000]/30000,'bandpass');

fname       = ops.fbinary;  %fullfile(ops.root, sprintf('%s.dat', ops.fbinary)); 
fidout      = fopen(fname, 'w');

% read the open ephys binary file

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
        
        offset = max(0, 2*NchanTOT*((NT - ops.ntbuff) * (ibatch-1) - 2*ops.ntbuff));
        
        fseek(fid, offset, 'bof');
        samples = fread(fid, [NchanTOT NTbuff], '*int16');
        
        if isempty(samples)
            break;
        end
        
        % delete the aux channels
        samples(end-auxchans+1:end,:) = [];
        
        nsampcurr = size(samples,2);
        if nsampcurr<NTbuff
            samples(:, nsampcurr+1:NTbuff) = repmat(samples(:,nsampcurr), 1, NTbuff-nsampcurr);
        end
        
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