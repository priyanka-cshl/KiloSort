function varargout = GUI_PANQI_Main(varargin)
% GUI_PANQI_MAIN MATLAB code for GUI_PANQI_Main.fig
%      GUI_PANQI_MAIN, by itself, creates a new GUI_PANQI_MAIN or raises the existing
%      singleton*.
%
%      H = GUI_PANQI_MAIN returns the handle to a new GUI_PANQI_MAIN or the handle to
%      the existing singleton*.
%
%      GUI_PANQI_MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_PANQI_MAIN.M with the given input arguments.
%
%      GUI_PANQI_MAIN('Property','Value',...) creates a new GUI_PANQI_MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_PANQI_Main_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_PANQI_Main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_PANQI_Main

% Last Modified by GUIDE v2.5 12-Feb-2019 22:01:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_PANQI_Main_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_PANQI_Main_OutputFcn, ...
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


% --- Executes just before GUI_PANQI_Main is made visible.
function GUI_PANQI_Main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_PANQI_Main (see VARARGIN)

% Choose default command line output for GUI_PANQI_Main
handles.output = hObject;

% Load User specific defaults 
if ~isempty(varargin)
    handles = LoadKilosortDefaults(handles, varargin{1});
else
    handles = LoadKilosortDefaults(handles, 'standard');
end

% defaults
addpath(genpath('/opt/KiloSort/')) % path to kilosort folder
addpath(genpath('/opt/npy-matlab/')) % path to npy-matlab scripts
handles.pathToYourConfigFile = '/opt/KiloSort/configFiles/'; % for this example it's ok to leave this path inside the repo, but for your own config file you *must* put it somewhere else!  

handles.SetUpSession_TotalSessions.Data(1) = 0;
% reposition GUI
movegui(hObject,'northwest'); 

% to maintain GUI size across various screen resolutions
set(handles.figure1,'Units','Normalized');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_PANQI_Main wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_PANQI_Main_OutputFcn(hObject, eventdata, handles) 
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
    clear rootpath datapath

    for j = 1:length(handles.db(i).expts) % for each file within the session
        rootpath = char(handles.FilePaths.Data(1));
        datapath = fullfile(char(handles.FilePaths.Data(2)),char(handles.db(i).expts(j)));
        run(fullfile(handles.pathToYourConfigFile, handles.YourConfigFile));
        ops.spkTh = handles.spike_det_settings.Data(2); % spike threshold in standard deviations (4)
        ops.Nfilt = handles.spike_det_settings.Data(1); % number of clusters to use (2-4 times more than Nchan, should be a multiple of 32)
        ops.ReFilter = handles.filter2binary.Value;
        ops.DeadChans = str2num(handles.IgnoreChannels.String);
        
        % override some settings
        if handles.init_from_data.Value
            ops.initialize      = 'fromData';
        else
            ops.initialize      = 'no';
        end

        disp('');
        disp(['processing session: ',fullfile(rootpath,datapath)]);
        master_file_PRIYANKA;
%         if handles.filter2binary.Value
%             master_file_PRIYANKA;
%         else
%             master_file_PANQI;
%         end
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
