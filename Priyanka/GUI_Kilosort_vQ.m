function varargout = GUI_Kilosort_vQ(varargin)
% GUI_KILOSORT_VQ MATLAB code for GUI_Kilosort_vQ.fig
%      GUI_KILOSORT_VQ, by itself, creates a new GUI_KILOSORT_VQ or raises the existing
%      singleton*.
%
%      H = GUI_KILOSORT_VQ returns the handle to a new GUI_KILOSORT_VQ or the handle to
%      the existing singleton*.
%
%      GUI_KILOSORT_VQ('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_KILOSORT_VQ.M with the given input arguments.
%
%      GUI_KILOSORT_VQ('Property','Value',...) creates a new GUI_KILOSORT_VQ or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_Kilosort_vQ_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_Kilosort_vQ_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_Kilosort_vQ

% Last Modified by GUIDE v2.5 17-Jan-2023 15:55:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_Kilosort_vQ_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_Kilosort_vQ_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GUI_Kilosort_vQ is made visible.
function GUI_Kilosort_vQ_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_Kilosort_vQ (see VARARGIN)

% Choose default command line output for GUI_Kilosort_vQ
handles.output = hObject;

% Load User specific defaults 
if ~isempty(varargin)
    handles = LoadKilosortDefaults(handles, varargin{1});
end

handles.SetUpSession_TotalSessions.Data(1) = 0;
% reposition GUI
movegui(hObject,'northwest'); 

% to maintain GUI size across various screen resolutions
set(handles.figure1,'Units','Normalized');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_Kilosort_vQ wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_Kilosort_vQ_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in SetUpSession_CLEAR.
function SetUpSession_CLEAR_Callback(hObject, eventdata, handles)
% hObject    handle to SetUpSession_CLEAR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.SetUpSession_TotalSessions.Data(1) = 0;
handles.db = [];
handles.session_list.String = {' '};
guidata(hObject, handles);


% --- Executes on button press in SetUpSession_AddNew.
function SetUpSession_AddNew_Callback(hObject, eventdata, handles)
% hObject    handle to SetUpSession_AddNew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
X = uigetfile_n_dir(char(fullfile(handles.FilePaths.Data(1),handles.FilePaths.Data(2))),...
    'Select experimental session folder');

if ~isempty (X)
    handles.SetUpSession_TotalSessions.Data(1) = handles.SetUpSession_TotalSessions.Data(1) + 1;
    y = handles.SetUpSession_TotalSessions.Data(1);
    handles.session_list.String(y:y+size(X,2)-1) = X;
    
    for i = 1:size(X,2)
        M =  regexp(char(X(i)),filesep,'split');
        handles.db(y).expts(i) = M(end);
    end
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in make_config_file.
function make_config_file_Callback(hObject, eventdata, handles)

set(hObject,'BackgroundColor','cyan','String','running ...');
pause(0.5);
guidata(hObject, handles);

for i = 1:length(handles.db)   % for each session
    clear rootpath datapath configpath
    
    if handles.ConcatenateSessions.Value
        uniquesessions = 1;
    else
        uniquesessions = length(handles.db(i).expts);
    end
    
    for j = 1:uniquesessions % for each file within the session
        rootpath = char(handles.FilePaths.Data(1));
        datapath = fullfile(char(handles.FilePaths.Data(2)),char(handles.db(i).expts(j)));
        
        if handles.ConcatenateSessions.Value
            localpath = fullfile(char(handles.FilePaths.Data(3)),...
                                 char(handles.FilePaths.Data(2)),...
                                 cell2mat(cellfun(@(x) ['_',x], handles.db(i).expts, 'UniformOutput', false)) );
            run(handles.YourConfigFile);
            for k = 2:length(handles.db(i).expts)
                ops.root = vertcat(ops.root, ...
                    fullfile(rootpath,char(handles.FilePaths.Data(2)),...
                                        char(handles.db(i).expts(k))));
            end
        else
            localpath = fullfile(char(handles.FilePaths.Data(3)),...
                                 char(handles.FilePaths.Data(2)),...
                                 char(handles.db(i).expts(j)));
            run(handles.YourConfigFile);
        end
        
        % overwrite some of the settings in ops
        ops.saveAUXbinaryfile = handles.auxTTLsave.Value;
        
        % to flag out aux channels from ephys channels
        ops.ActiveChannels = 1:(handles.recording_settings.Data(1) - handles.recording_settings.Data(2));
        
        % to reorder channels if record node was before the channelmap node
        if ~isempty(handles.ReorderChannels)
            ops.ActiveChannels = handles.ReorderChannels;
        end
        
        % if useless channels were recorded - skip them from the binary file
        [~,notConnected] = ismember(eval(handles.InactiveChannels.String), ops.ActiveChannels);
        ops.ActiveChannels(notConnected) = [];
        % not sure the inactive channel works for batch Q

        % just parse some info to ops the way kilosort likes it
        ops.Nchan = numel(ops.ActiveChannels); % number of active channels
        ops.NchanTOT = ops.Nchan;  % we don't use this
        
        % create a list of valid channels - account for the unloaded channels
        ops.DeadChans = eval(handles.IgnoreChannels.String);
        [~,chans2omit] = ismember(ops.DeadChans, ops.ActiveChannels);
        ops.ValidChannels = true(ops.Nchan,1);
        ops.ValidChannels(chans2omit(chans2omit~=0)) = false;
        
        %ops.Nfilt = 32*ceil((ops.Nchan*handles.spike_det_settings.Data(1))/32); % number of clusters to use (2-4 times more than Nchan, should be a multiple of 32)   
        ops.Nfilt = 32*ceil(((ops.Nchan - numel(chans2omit))*handles.spike_det_settings.Data(1))/32); % number of clusters to use (2-4 times more than Nchan, should be a multiple of 32)
        
        disp(['Setting nTemplates to ',num2str(ops.Nfilt)]);
        ops.spkTh = handles.spike_det_settings.Data(2); % spike threshold in standard deviations (4)
        ops.ReFilter = handles.filter2binary.Value;
        ops.CAR = handles.computeCAR.Value;
        

        
        if handles.init_from_data
            ops.initialize      = 'fromData';
        else
            ops.initialize      = 'no';
        end
        
        ops.datatype = 'flatbinary'; %'opendat';
        ops.Nchanbinary = handles.recording_settings.Data(1);
                    
        [binarypath, binaryfile, ext] = fileparts(ops.fbinary);
        
        sorted = 0;
        % check if the session has already been sorted
        if exist(fullfile(handles.ServerPath,datapath)) || exist(fullfile(binarypath,'mybinaryfile.dat'))
            reply = input('A local sorting folder for this session already exists. \nDo you want to overwrite? Y/N [Y]: ','s');
            if ~strcmp(reply,'Y')
                sorted = 1;
            end
        end
        
        if ~sorted
            if ~exist(binarypath,'dir')
                mkdir(binarypath);
                fileattrib(binarypath,'+w','a');
            end
            
            disp('');
            disp(['processing session: ',fullfile(rootpath,datapath)]);
            master_file_Albeanu_VQ;
            % change permissions
            command = ['chmod -R 777 ',binarypath];
            system(command);
        else
            disp('');
            disp(['skipping session: ',fullfile(rootpath,datapath)]);
        end
    end
end

display('done!');
% handles.make_config_file.String = 'GO';
% handles.make_config_file.BackgroundColor = [0.9400 0.9400 0.9400];
set(hObject,'BackgroundColor',[0.9400 0.9400 0.9400],'String','GO');
pause(0.5);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SetUpSession_AddNew_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SetUpSession_AddNew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called