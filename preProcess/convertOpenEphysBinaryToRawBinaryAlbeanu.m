function ops = convertOpenEphysBinaryToRawBinaryAlbeanu(ops)

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
        
        nsampcurr = size(samples,2);
        if nsampcurr<NTbuff
            samples(:, nsampcurr+1:NTbuff) = repmat(samples(:,nsampcurr), 1, NTbuff-nsampcurr);
        end
        
        samples = samples';
        
        % delete the aux channels
        samples(:,end-auxchans+1:end) = [];
        
        % reorder the channels
        samples = samples(:,ops.ActiveChannels);
        
        if ops.ReFilter
            % filter the data
            samples = filter(b,a,samples);
            samples = flipud(samples);
            samples = filter(b,a,samples);
            samples = flipud(samples);
            if ops.CAR
                samples = samples - mean(samples(:,find(ops.ValidChannels)),2);
            end
            % make noisy channels zero
            samples(:,find(~ops.ValidChannels)) = 0;
        end
        
        samples         = samples';
        
        % write to binary file
        fwrite(fidout, samples, 'int16');
        
        nsamps = nsamps + size(samples,2);
        
    end
    ops.nSamplesBlocks(k) = nsamps;
end

fclose(fidout);

toc

% %
% clear fs
% for j = 1:ops.Nchan
%    fs{j} = dir(fullfile(ops.root, sprintf(ops.channeltag, ops.ActiveChannels(j)) ));
% end
% nblocks = cellfun(@(x) numel(x), fs);
% if numel(unique(nblocks))>1
%    error('different number of blocks for different channels!') 
% end
% %
% nBlocks     = unique(nblocks);
% nSamples    = 1024;  % fixed to 1024 for now!
% 
% fid = cell(ops.Nchan, 1);
% 
% tic
% for k = 1:nBlocks
%     for j = 1:ops.Nchan
%         fid{j}             = fopen(fullfile(ops.root, fs{j}(k).name));
%         % discard header information
%         fseek(fid{j}, 1024, 0);
%     end
%     %
%     nsamps = 0;
%     flag = 1;
%     while 1
%         samples = zeros(nSamples * 1000, ops.Nchan, 'int16');
%         for j = 1:ops.Nchan
%             collectSamps    = zeros(nSamples * 1000, 1, 'int16');
%             
%             rawData         = fread(fid{j}, 1000 * (nSamples + 6), '1030*int16', 10, 'b');
% 
%             nbatches        = ceil(numel(rawData)/(nSamples+6));
%             for s = 1:nbatches
%                 rawSamps = rawData((s-1) * (nSamples + 6) +6+ [1:nSamples]);
%                 collectSamps((s-1)*nSamples + [1:nSamples]) = rawSamps;
%             end
%             samples(:,j)         = collectSamps;
%         end
%         
%         if nbatches<1000
%             flag = 0;
%         end
%         if flag==0
%             samples = samples(1:s*nSamples, :);
%         end
%         
%         if ops.ReFilter
%             % filter the data
%             samples = filter(b,a,samples);
%             samples = flipud(samples);
%             samples = filter(b,a,samples);
%             samples = flipud(samples);
%             if ops.CAR
%                 samples = samples - mean(samples(:,find(ops.ValidChannels)),2);
%             end
%             % make noisy channels zero
%             samples(:,find(~ops.ValidChannels)) = 0;
%         end
%         
%         samples         = samples';
%         
%         % write to binary file
%         fwrite(fidout, samples, 'int16');
% 
%         nsamps = nsamps + size(samples,2);
%         
%         if flag==0
%             break;
%         end
%     end
%     ops.nSamplesBlocks(k) = nsamps;
%     
%     for j = 1:ops.Nchan
%        fclose(fid{j}); 
%     end
%     
% end
%     
% fclose(fidout);
% 
% toc