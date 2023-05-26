function varargout = Interfaz_EEG_Supremo(varargin)
% INTERFAZ_EEG_SUPREMO MATLAB code for Interfaz_EEG_Supremo.fig
%      INTERFAZ_EEG_SUPREMO, by itself, creates a new INTERFAZ_EEG_SUPREMO or raises the existing
%      singleton*.
%   
%      H = INTERFAZ_EEG_SUPREMO returns the handle to a new INTERFAZ_EEG_SUPREMO or the handle to
%      the existing singleton*.
%
%      INTERFAZ_EEG_SUPREMO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INTERFAZ_EEG_SUPREMO.M with the given input arguments.
%
%      INTERFAZ_EEG_SUPREMO('Property','Value',...) creates a new INTERFAZ_EEG_SUPREMO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Interfaz_EEG_Supremo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Interfaz_EEG_Supremo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Interfaz_EEG_Supremo

% Last Modified by GUIDE v2.5 24-Apr-2023 15:40:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Interfaz_EEG_Supremo_OpeningFcn, ...
                   'gui_OutputFcn',  @Interfaz_EEG_Supremo_OutputFcn, ...
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


% --- Executes just before Interfaz_EEG_Supremo is made visible.
function Interfaz_EEG_Supremo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Interfaz_EEG_Supremo (see VARARGIN)

% Choose default command line output for Interfaz_EEG_Supremo
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Interfaz_EEG_Supremo wait for user response (see UIRESUME)
% uiwait(handles.figure1);                                          

axes(handles.axes1);
[x,map]=imread('Fondo_EEG_ABC.png');
image(x)
colormap(map);
axis off
hold on

%global bt;
global estado;
estado = 0;

% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};

% Cargar parametros de remoción de artefactos
% Ajuste de parámetros para ejecutar algoritmo BSS y su implementación

% Conectar ESP32 por Bluetooth
%bt = bluetooth('ESP32-BT-Car', 1)

while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG'); end

% create a new inlet
global inlet;
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

% Exportar modelo de red
filename = 'ABC_CNN.h5'
lgraph = importKerasLayers(filename,'ImportWeights',true);

% Convertir a modelo de red
global net;
net = assembleNetwork(lgraph)

disp('Now receiving data...');



% --- Outputs from this function are returned to the command line.
function varargout = Interfaz_EEG_Supremo_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in buttonComenzar.
function buttonComenzar_Callback(hObject, eventdata, handles) % Comenzar
global estado;
estado = 1;
% hObject    handle to buttonComenzar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Variables de GUI
x = [0];
a = 0;
c = 1;
color = ["#1C27E9" "#1CE9E4" "#B7DC00" "#DA337F" "#DD5906" "#D81E37" "#a7a1d8"];

% Variables de Algoritmo
global net;
global inlet;
signal = zeros(1,4);
i=0;
wl = 16.8;
ws = 0.2;
bss_alg = 'iwasobi'; 
bss_opt = {'eigratio',1e6};
crit_alg = 'eog_fd';
crit_opt = {'range',[2 21]};

% Cargar filtros para la señal
load('LP70.mat');             %Filter Designer: filtro pasa bajas
load('Notch60hz.mat');          %Filter Designer: filtro notch
load('HP05.mat');             %Filter Designer: filtro pasa altas
% Filtro en ritmos alpha y beta
load('LP30.mat');             %Filter Designer: filtro pasa bajas
load('HP8.mat');             %Filter Designer: filtro pasa altas

% Cargar máximos y mínimos de las características
load('Max&MinABC.mat')

while estado ~= 0
    % get data from the inlet
    [vec,ts] = inlet.pull_sample();
    % and display it
%     fprintf('%.2f\t',vec);
%     fprintf('%.5f\n',ts);
    
%     signal(i+1,1:4) = signal(i,1:4);
%     signal(i,1:4) = vec;
    MAV = 0;
    MAVER = 0;
    signal = cat(1,vec,signal);
    [y,x] = size(signal);
    if y > 600
        signal(601,:) = [];
        %condición para calcular cada 50 muestras
        if mod(i,100) == 0
            % Filtro de 0.5 a 70 Hz
            filteredsignal_low(:,:)= filter(LP70, 1, signal(:,:));          %Filtro pasa bajas
            filteredsignal_high(:,:)= filter(HP05, 1, filteredsignal_low(:,:));          %Filtro pasa altas
            Data_Filtered(:,:)= filter(NOTCH60, 1, filteredsignal_high(:,:)); %Filtro notch
            
            %Remoción de artefactos
            EEG.data=Data_Filtered;
            EEG.srate=200;
            EEG.pnts=600;   % NUMBER OF POINTS PER TRIAL
            EEG.nbchan=4;
            EEG.chanlocs= [];
            EEG.trials=1;

            OUTEEG_EOG = pop_autobsseog(EEG,wl,ws,bss_alg,bss_opt,crit_alg,crit_opt);  %Algoritmo BSS con remocion EOG
            %OUTEEG_EMG = pop_autobssemg(OUTEEG_EOG,wl,ws,bss_alg,bss_opt,'emg_psd',{'ratio',10,'fs',200,'femg',15,'estimator',spectrum.welch({'Hamming'},80),'range',[0  32]});
            Data_AR(:,:)=OUTEEG_EOG.data';

            fsignal_low(:,:) = filter(LP30, 1, Data_AR(:,:));          %Filtro pasa bajas
            fsignal_high(:,:) = filter(HP8, 1, fsignal_low(:,:));         %Filtro pasa altas
            Data_ERDERS(:,:) = fsignal_high(:,:);

            % Calculo de caracteristicas
            % recorte de señal
            Data_F = Data_Filtered(121:520,:);
            Data_ER = Data_ERDERS(151:550,:);
            
            Data_CNN = cat(2,Data_F,Data_ER);

            prediccion=round(net.predict(Data_CNN));
            if prediccion(1)==1
                clase="Derecha"
                a = a+1;
            elseif prediccion(2)==1
                clase="Izquierda"
                a = a-1;
            else
                clase="Calma"
                if a > 0
                    a = a-1;
                elseif a < 0
                    a = a+1;
                else
                    a = 0;
                end
            end
            
            if a >= 4
                a = 4;
            elseif a <= -4
                a = -4;
            end
            
            % Graficar Barra Indicadora
            x = [0, a];
            y = [0, 0];
            
            switch a
                case 0
                    c = 1;
                case 1
                    c = 2;
                case 2
                    c = 3;
                case -1
                    c = 4;
                case -2
                    c = 5;
                case -3
                    c = 6;
            end
            
            % Representar estado de calma
            if a == 0
                x = [-4,4];
                c = 7;
            end
            
            axes(handles.axes5);
            plot(x,y,'color',color(c),'LineWidth',37)
            xticks([])
            yticks([])
            xlim([-4 4])
            ylim([-1 1])
            drawnow;
        end

        i=i+1;
    end
end


% --- Executes on button press in buttonPausar.
function buttonPausar_Callback(hObject, eventdata, handles) % Pausar
global estado;
estado = 0;
% hObject    handle to buttonPausar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
