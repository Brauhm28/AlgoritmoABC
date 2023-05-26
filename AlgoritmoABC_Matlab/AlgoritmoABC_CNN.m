% instantiate the library
clear all, close all, clc;

disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};

% Cargar filtros para la señal
load('LP70.mat');             %Filter Designer: filtro pasa bajas
load('Notch60hz.mat');          %Filter Designer: filtro notch
load('HP05.mat');             %Filter Designer: filtro pasa altas
% Filtro en ritmos alpha y beta
load('LP30.mat');             %Filter Designer: filtro pasa bajas
load('HP8.mat');             %Filter Designer: filtro pasa altas

% Cargar máximos y mínimos de las características
load('Max&MinABC.mat')

% Cargar parametros de remoción de artefactos
% Ajuste de parámetros para ejecutar algoritmo BSS y su implementación
wl = 16.8;
ws = 0.2;
bss_alg = 'iwasobi'; 
bss_opt = {'eigratio',1e6};
crit_alg = 'eog_fd';
crit_opt = {'range',[2 21]};

while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG'); end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

signal = zeros(1,4);
i=0;

% Exportar modelo de red
filename = 'ABC_CNN.h5'
lgraph = importKerasLayers(filename,'ImportWeights',true);

% Convertir a modelo de red
net = assembleNetwork(lgraph)

disp('Now receiving data...');

%figure

while true
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
            elseif prediccion(2)==1
                clase="Izquierda"
            else
                clase="Calma"
            end
            
            % Graficar señal
            plot(Data_Filtered)
            drawnow;
        end

        i=i+1;
        if i >= 50000
            break
        end
    end

end