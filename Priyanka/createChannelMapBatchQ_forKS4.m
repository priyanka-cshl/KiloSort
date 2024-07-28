%  create a channel map for KS4

Nchannels = 40;
connected = true(Nchannels, 1);
chanMap   = 1:Nchannels;
chanMap0ind = chanMap - 1;
% 
% xcoords = []; ycoords = []; kcoords = [];
% for tetrodesbundles = 1:(Nchannels/8)
%     % every bundle
%     xcoords = horzcat(xcoords, (2*[8 8 16 16 32 32 40 40] + (tetrodesbundles-1)*200));
%     ycoords = horzcat(ycoords, 2*[8 16 16 8 8 16 16 8]);
%     kcoords = horzcat(kcoords, ([1 1 1 1 2 2 2 2] + (tetrodesbundles-1)*2));
% end

xcoords   = repmat([1 2 3 4 5 6 7 8]', 1, Nchannels/8);
%xcoords   = repmat([1 2 3 4 20 21 22 23]', 1, Nchannels/8);
xcoords   = xcoords*10; % + repmat(200*(1:size(xcoords,2)),8,1);
xcoords   = xcoords(:);

ycoords   = 200*repmat(1:Nchannels/8, 8, 1);
ycoords   = ycoords(:);

temp = ycoords;
ycoords = xcoords;
xcoords = temp;

kcoords   = repmat(1:Nchannels/4, 4, 1);
kcoords   = kcoords(:);

fs = 30000; % sampling frequency

save('/opt/KS4_chanmap_new3.mat', ...
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