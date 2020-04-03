%% Open ePhys to individual binary script
%%% fills gaps in acquisition -- i.e where timestamps expected by sampling 
%%% rate dropped 


%% 32 channel tetrode
clear variables
close all


[data, timestamps, info] = load_open_ephys_data_faster(strcat('110_CH1.continuous'),'unscaledInt16');

SampleRate=info.header.sampleRate;


nts=length([timestamps(1):1/SampleRate:timestamps(end)]);
AllTimes=[timestamps(1):1/SampleRate:timestamps(end)]';

%DataMatrix=zeros(1,nts,'int16');


for i=1:32
    i
    tic
    DataMatrix=zeros(1,nts,'int16');

    [data, Timestamps, info] = load_open_ephys_data_faster(strcat('110_CH',num2str(i),'.continuous'),'unscaledInt16');
    
    indices=1+round((Timestamps-Timestamps(1))*SampleRate);
    DataMatrix(1,indices)=data;
    
    fid = fopen(fullfile(cd,strcat('binaries/110_CH',num2str(i),'.bin')),'w');
    fwrite(fid, DataMatrix, 'int16');
    fclose(fid);
    
    toc
end


