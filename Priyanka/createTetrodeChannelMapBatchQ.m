function [] = createTetrodeChannelMapBatchQ(numElectrodes,shankspacing,savename)

%  create a channel map

Nchannels = numElectrodes; %ops.Nchan;
connected = true(Nchannels, 1);
chanMap   = 1:Nchannels;
chanMap0ind = chanMap - 1;

xcoords = []; ycoords = []; kcoords = [];
for tetrodes = 1:(numElectrodes/8)
    [x,y,k] = maketetrode();
    xcoords = horzcat(xcoords, x+shankspacing*(tetrodes-1));
    ycoords = horzcat(ycoords, y);
    kcoords = horzcat(kcoords, k);
end
% xcoords   = repmat([1 2 3 4 5 6 7 8]', 1, Nchannels/8);
% xcoords   = xcoords*electrodespacing; %xcoords*10; % + repmat(200*(1:size(xcoords,2)),8,1);
% xcoords   = xcoords(:);
% 
% ycoords   = tetrodespacing*repmat(1:Nchannels/8, 8, 1); %200*repmat(1:Nchannels/8, 8, 1);
% ycoords   = ycoords(:);
% 
% temp = ycoords;
% ycoords = xcoords;
% xcoords = temp;
% 
% kcoords   = repmat(1:Nchannels/4, 4, 1);
% kcoords   = kcoords(:);

fs = 30000; % sampling frequency

save(savename, ...
    'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')

    function [x_coords,y_coords,k_coords] = maketetrode()
        %x_coords = [10 6.12 -10 -1.8 10 6.12 -10 -1.8];
        x_coords = [10 0 -10 0 10 0 -10 0];
        y_coords = [0 10 1.22 -10 30 40 31.22 20];
        k_coords = [1 1 1 1 1 1 1 1];
    end

end
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