function [] = createChannelMapBatchQ_v2(ChanMapPath,ValidChannels,fs)

%  create a channel map

Nchannels = numel(ValidChannels); % total ephys channels recorded for batch Q
connected = true(numel(find(ValidChannels)), 1);
chanMap   = 1:numel(find(ValidChannels));
chanMap0ind = chanMap - 1;
%chanMap0ind = find(ValidChannels) - 1;

xcoords   = repmat([1 2 3 4 5 6 7 8]', 1, Nchannels/8);
xcoords   = xcoords*10; % + repmat(200*(1:size(xcoords,2)),8,1);
xcoords   = xcoords(:);

ycoords   = 200*repmat(1:Nchannels/8, 8, 1);
ycoords   = ycoords(:);

kcoords   = repmat(1:Nchannels/4, 4, 1);
kcoords   = kcoords(:);

%fs = 30000; % sampling frequency

% delete all invalid indices
xcoords(find(~ValidChannels),:) = [];
ycoords(find(~ValidChannels),:) = [];
kcoords(find(~ValidChannels),:) = [];

save(ChanMapPath, ...
    'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')
%%

% kcoords is used to forcefully restrict templates to channels in the same
% channel group. An option can be set in the master_file to allow a fraction 
% of all templates to span more channel groups, so that they can capture shared 
% noise across all channels. This option is

% ops.criterionNoiseChannels = 0.2; 

% if this number is less than 1, it will be treated as a fraction of the total number of clusters

% if this number is larger than 1, it will be treated as the "effective
% number" of channel groups at which to set the threshold. So if a template
% occupies more than this many channel groups, it will not be restricted to
% a single channel group. 
end