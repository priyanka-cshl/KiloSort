function ops = convertOpenEphysToRawBInaryPriyanka(ops)
[b,a] = butter(3,2*[300 6000]/30000,'bandpass');

fname       = ops.fbinary;  %fullfile(ops.root, sprintf('%s.dat', ops.fbinary)); 
fidout      = fopen(fname, 'w');

% load channel map if you want to eliminate certain channels from being
% used for reference

if isfield(ops, 'DeadChans')
    Chans2Omit = ops.DeadChans;
else
    Chans2Omit = [];
end

if isfield(ops, 'ReFilter')
    FilterData = ops.ReFilter;
else
    FilterData = 0; % default is to not filter the data again
end

%
clear fs
for j = 1:ops.Nchan
   fs{j} = dir(fullfile(ops.root, sprintf(ops.channeltag, j) ));
end
nblocks = cellfun(@(x) numel(x), fs);
if numel(unique(nblocks))>1
   error('different number of blocks for different channels!') 
end
%
nBlocks     = unique(nblocks);
nSamples    = 1024;  % fixed to 1024 for now!

fid = cell(ops.Nchan, 1);

tic
for k = 1:nBlocks
    for j = 1:ops.Nchan
        fid{j}             = fopen(fullfile(ops.root, fs{j}(k).name));
        % discard header information
        fseek(fid{j}, 1024, 0);
    end
    %
    nsamps = 0;
    flag = 1;
    while 1
        samples = zeros(nSamples * 1000, ops.Nchan, 'int16');
        for j = 1:ops.Nchan
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
       
        samples         = samples';
        
        if FilterData
            % filter the data
            for foo = 1:size(samples,1)
                samples(foo,:) = filter(b,a,samples(foo,:));
            end
            
            if ~isempty(Chans2Omit)
                samples(Chans2Omit,:) = NaN;
            end
            
            % compute common average
            CAR = int16(nanmean(samples,1));
            % take a specific channel as ref
            % CAR = samples(20,:);
            
            % subtract common average
            for foo = 1:size(samples,1)
                samples(foo,:) = samples(foo,:) - CAR;
            end
        
        end
        
        if ~isempty(Chans2Omit)
            samples(Chans2Omit,:) = 0;
        end
        
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
    
end
    
fclose(fidout);

toc