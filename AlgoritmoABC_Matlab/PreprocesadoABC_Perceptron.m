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

%% Calculo de caracteristicas

carVec = [];

%Data_Move = Data_ArtRem(651:1050,:,:);
Data_MoveAR = [permute(signalDiv(651:1050,:,:),[3 2 1]); permute(signalDiv(1601:2000,:,:),[3 2 1])];
Data_MoveAR = permute(Data_MoveAR,[3 2 1]);

Data_MoveER = [permute(Data_ER(701:1100,:,:),[3 2 1]); permute(Data_ER(1601:2000,:,:),[3 2 1])];
Data_MoveER = permute(Data_MoveER,[3 2 1]);

%%
MAV = 0;
MAVER = 0;
for i = 1:numRec*2
    
    if any(max(Data_MoveAR(:,:,i)) > 600 | min(Data_MoveAR(:,:,i)) < -700)
        disp(i)
    end
    
    % Caracteristicas de señal completa
    
    % Calcular la media
    media = mean(Data_MoveAR(:,:,i));
    % Calcular la moda
    moda = mode(Data_MoveAR(:,:,i));
    % Calcular la mediana
    mediana = median(Data_MoveAR(:,:,i));
    % Desviación estandar
    desvEstandar = std(Data_MoveAR(:,:,i));
    % Varianza
    varianza = var(Data_MoveAR(:,:,i));
    % Maximo y mínimo
    maximo = max(Data_MoveAR(:,:,i));
    minimo = min(Data_MoveAR(:,:,i));
    % Calcular Raiz Cuadrada Media (RMS)
    RMS = rms(Data_MoveAR(:,:,i));
    % Potencia
    x_t = Data_MoveAR(:,:,i).*Data_MoveAR(:,:,i);
    potencia = (sum(x_t))/(2*length(Data_MoveAR(:,:,i)) + 1);
    %Coeficiente de Fisher
    dum = Data_MoveAR(:,3,i) - media(3);            %Diferencias respecto a la media
    dum = dum.^3;               %Diferencias al cubo
    dum = sum(dum);             %Suma de las diferencias al cubo
    m3 = dum/length(Data_MoveAR(:,3,i));         %Momento de orden 3
    CAFc3 = m3/(desvEstandar(3)^3);
    
    dum = Data_MoveAR(:,4,i) - media(4);            %Diferencias respecto a la media
    dum = dum.^3;               %Diferencias al cubo
    dum = sum(dum);             %Suma de las diferencias al cubo
    m3 = dum/length(Data_MoveAR(:,4,i));         %Momento de orden 3
    CAFc4 = m3/(desvEstandar(4)^3);
    %skewness(x)

    % Coeficiente de Pearson
    CAPc3= (media(3)-moda(3))/desvEstandar(3);
    CAPc4= (media(4)-moda(4))/desvEstandar(4);
    
    %Coeficiente de Bowleyq
    y = sort(Data_MoveAR(:,:,i));
    Q_1 = median(y(find(y<median(y))));
    Q_2 = median(y);
    Q_3 = median(y(find(y>median(y))));
    
    CAB = ( Q_3+Q_1-2*mediana )/( Q_3-Q_1 );
    
    % Valor absoluto medio
    for j=1:length(Data_MoveAR(:,:,i))
        MAV = MAV+abs(Data_MoveAR(j,:,i));
    end
    MAV = MAV/length(Data_MoveAR(:,:,i));
    
    % Características de señal ERD-ERS
    
    % Calcular la media
    mediaER = mean(Data_MoveER(:,:,i));
    % Calcular la moda
    modaER = mode(Data_MoveER(:,:,i));
    % Calcular la mediana
    medianaER = median(Data_MoveER(:,:,i));
    % Desviación estandar
    desvEstandarER = std(Data_MoveER(:,:,i));
    % Varianza
    varianzaER = var(Data_MoveER(:,:,i));
    % Maximo y mínimo
    maximoER = max(Data_MoveER(:,:,i));
    minimoER = min(Data_MoveER(:,:,i));
    % Calcular Raiz Cuadrada Media (RMS)
    RMSER = rms(Data_MoveER(:,:,i));
    % Potencia
    x_tER = Data_MoveER(:,:,i).*Data_MoveER(:,:,i);
    potenciaER = (sum(x_tER))/(2*length(Data_MoveER(:,:,i)) + 1);
    %Coeficiente de Fisher
    dum = Data_MoveER(:,3,i) - mediaER(3);            %Diferencias respecto a la media
    dum = dum.^3;               %Diferencias al cubo
    dum = sum(dum);             %Suma de las diferencias al cubo
    m3 = dum/length(Data_MoveER(:,3,i));         %Momento de orden 3
    CAFc3ER = m3/(desvEstandarER(3)^3);
    
    dum = Data_MoveER(:,4,i) - mediaER(4);            %Diferencias respecto a la media
    dum = dum.^3;               %Diferencias al cubo
    dum = sum(dum);             %Suma de las diferencias al cubo
    m3 = dum/length(Data_MoveER(:,4,i));         %Momento de orden 3
    CAFc4ER = m3/(desvEstandarER(4)^3);
    %skewness(x)

    % Coeficiente de Pearson
    CAPc3ER= (mediaER(3)-modaER(3))/desvEstandarER(3);
    CAPc4ER= (mediaER(4)-modaER(4))/desvEstandarER(4);
    
    %Coeficiente de Bowleyq
    y = sort(Data_MoveER(:,:,i));
    Q_1 = median(y(find(y<median(y))));
    Q_2 = median(y);
    Q_3 = median(y(find(y>median(y))));
    
    CABER = ( Q_3+Q_1-2*medianaER )/( Q_3-Q_1 );
    
    % Valor absoluto medio
    for j=1:length(Data_MoveER(:,:,i))
        MAVER = MAVER+abs(Data_MoveER(j,:,i));
    end
    MAVER = MAVER/length(Data_MoveER(:,:,i));
    
    charVecC3(i,:) = [media(3), moda(3), mediana(3), desvEstandar(3), varianza(3), maximo(3), minimo(3), RMS(3), potencia(3), CAFc3, CAPc3, CAB(3), MAV(3), mediaER(3), modaER(3), medianaER(3), desvEstandarER(3), varianzaER(3), maximoER(3), minimoER(3), RMSER(3), potenciaER(3), CAFc3ER, CAPc3ER, CABER(3), MAVER(3)];
    charVecC4(i,:) = [media(4), moda(4), mediana(4), desvEstandar(4), varianza(4), maximo(4), minimo(4), RMS(4), potencia(4), CAFc4, CAPc4, CAB(4), MAV(4), mediaER(4), modaER(4), medianaER(4), desvEstandarER(4), varianzaER(4), maximoER(4), minimoER(4), RMSER(4), potenciaER(4), CAFc4ER, CAPc4ER, CABER(4), MAVER(4)];
end
%%
% Rescalar vectores de caracteristicas
charVec = cat(2,charVecC3,charVecC4);

maxCV = max(charVec,[],1);
minCV = min(charVec,[],1);

charVec = rescale(charVec,-1,1,'InputMin',minCV,'InputMax',maxCV);

%% Extracción del identificador de movimiento (D, I o C)
for i = 1:numRec
    a = split(sigName(i),[""]);
    letter(i,:) = a(3);
end
for i = 1:numRec
    letter(numRec+i,:) = cellstr("C");
end

%% Se forma un vector con todas las características y su identificador 
charVec = cellstr([string(letter), string(charVec)]);

%%
% Convert cell to a table and use first row as variable names
namesVar = ["Type","MediaC3","ModaC3","MedianaC3","DesEstC3","VarianzaC3","MaximoC3","MinimoC3","RMSC3","PotenciaC3","CAFC3","CAPC3","CABC3","MAVC3","MediaC4","ModaC4","MedianaC4","DesEstC4","VarianzaC4","MaximoC4","MinimoC4","RMSC4","PotenciaC4","CAFC4","CAPC4","CABC4","MAVC4","MediaC3-ER","ModaC3-ER","MedianaC3-ER","DesEstC3-ER","VarianzaC3-ER","MaximoC3-ER","MinimoC3-ER","RMSC3-ER","PotenciaC3-ER","CAFC3-ER","CAPC3-ER","CABC3-ER","MAVC3-ER","MediaC4-ER","ModaC4-ER","MedianaC4-ER","DesEstC4-ER","VarianzaC4-ER","MaximoC4-ER","MinimoC4-ER","RMSC4-ER","PotenciaC4-ER","CAFC4-ER","CAPC4-ER","CABC4-ER","MAVC4-ER"];
T = cell2table(charVec,'VariableNames',namesVar);

% Write the table to a CSV file
writetable(T,'CharVectorABC-Scaled.csv');

%%
% Guardar los valores de máximo y minímo en las características
save('Max&MinABC.mat','maxCV','minCV');
