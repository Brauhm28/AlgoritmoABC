clear all, close all, clc;

data=importdata('signalR&L_ABC.txt');

for i=1:4
    fullData(:,i,:) = data.data(:,i);
end

%% Filtro de 0.5 a 70 Hz

load('LP70.mat');             %Filter Designer: filtro pasa bajas
load('Notch60hz.mat');          %Filter Designer: filtro notch
load('HP05.mat');             %Filter Designer: filtro pasa altas

filteredsignal_low(:,:)= filter(LP70, 1, fullData(:,:));          %Filtro pasa bajas
filteredsignal_high(:,:)= filter(HP05, 1, filteredsignal_low(:,:));          %Filtro pasa altas
Data_Filtered(:,:)= filter(NOTCH60, 1, filteredsignal_high(:,:)); %Filtro notch

%% División de la señan cada 10 segundos

numRec = size(Data_Filtered,1)/2000;

for i = 1:numRec
    signalDiv(:,:,i) = Data_Filtered((i-1)*2000+1:i*2000,:,:);
    sigName(i,1) = data.textdata((i-1)*2000+1);
end

%signalDiv = permute(signalDiv,[2 1 3]);

%% Ajuste de parámetros para ejecutar algoritmo BSS y su implementación
wl = 16.8;
ws = 0.2;
bss_alg = 'iwasobi'; 
bss_opt = {'eigratio',1e6};
crit_alg = 'eog_fd';
crit_opt = {'range',[2 21]};

for i = 1:numRec
    EEG.data=signalDiv(:,:,i)';
    EEG.srate=200;
    EEG.pnts=2000;   % NUMBER OF POINTS PER TRIAL
    EEG.nbchan=4;
    EEG.chanlocs= [];
    EEG.trials=1;

    OUTEEG_EOG = pop_autobsseog(EEG,wl,ws,bss_alg,bss_opt,crit_alg,crit_opt);  %Algoritmo BSS con remocion EOG
    %OUTEEG_EMG = pop_autobssemg(OUTEEG_EOG,wl,ws,bss_alg,bss_opt,'emg_psd',{'ratio',10,'fs',200,'femg',15,'estimator',spectrum.welch({'Hamming'},80),'range',[0  32]});

    Data_ArtRem(:,:,i)=OUTEEG_EOG.data';
end
%Algoritmo BSS con remocion EMG

%% Filtro en ritmos alpha y beta
load('LP30.mat');             %Filter Designer: filtro pasa bajas
load('HP8.mat');             %Filter Designer: filtro pasa altas

for i = 1:numRec
    fsignal_low(:,:) = filter(LP30, 1, Data_ArtRem(:,:,i));          %Filtro pasa bajas
    fsignal_high(:,:) = filter(HP8, 1, fsignal_low(:,:));         %Filtro pasa altas
    Data_ER(:,:,i) = fsignal_high(:,:);
end

%%

Data_Move = [permute(signalDiv(651:1050,:,:),[3 2 1]); permute(signalDiv(1601:2000,:,:),[3 2 1])];
Data_Move = permute(Data_Move,[3 2 1]);

Data_ERD = [permute(Data_ER(701:1100,:,:),[3 2 1]); permute(Data_ER(1601:2000,:,:),[3 2 1])];
Data_ERD = permute(Data_ERD,[3 2 1]);

Data_Total = cat(2, Data_Move, Data_ERD);

for i=1:numRec*2
    DataT(1+(i-1)*400:i*400,:) = Data_Total(:,:,i);
end
%32700
%%
DataTable = array2table(DataT);
% Write the table to a CSV file
writetable(DataTable,'DataABC_CNN.csv');

%% Extracción del identificador de movimiento (D, I o C)
for i = 1:numRec
    a = split(sigName(i),[""]);
    letter(i,:) = a(3);
end
for i = 1:numRec
    letter(numRec+i,:) = cellstr("C");
end

letterTable = array2table(letter);
% Write the table to a CSV file
writetable(letterTable,'EtiquetaABC_CNN.csv');
