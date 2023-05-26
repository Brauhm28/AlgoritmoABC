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
filename = 'ABC_Perceptron.h5'
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
        if mod(i,200) == 0
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
            Data_ArtRem = Data_Filtered(121:520,:);
            Data_ER = Data_ERDERS(151:550,:);
            % Caracteristicas de señal completa

            % Caracteristicas de señal completa

            % Calcular la media
            media = mean(Data_ArtRem(:,:));
            % Calcular la moda
            moda = mode(Data_ArtRem(:,:));
            % Calcular la mediana
            mediana = median(Data_ArtRem(:,:));
            % Desviación estandar
            desvEstandar = std(Data_ArtRem(:,:));
            % Varianza
            varianza = var(Data_ArtRem(:,:));
            % Maximo y mínimo
            maximo = max(Data_ArtRem(:,:));
            minimo = min(Data_ArtRem(:,:));
            % Calcular Raiz Cuadrada Media (RMS)
            RMS = rms(Data_ArtRem(:,:));
            % Potencia
            x_t = Data_ArtRem(:,:).*Data_ArtRem(:,:);
            potencia = (sum(x_t))/(2*length(Data_ArtRem(:,:)) + 1);
            %Coeficiente de Fisher
            dum = Data_ArtRem(:,3) - media(3);            %Diferencias respecto a la media
            dum = dum.^3;               %Diferencias al cubo
            dum = sum(dum);             %Suma de las diferencias al cubo
            m3 = dum/length(Data_ArtRem(:,3));         %Momento de orden 3
            CAFc3 = m3/(desvEstandar(3)^3);

            dum = Data_ArtRem(:,4) - media(4);            %Diferencias respecto a la media
            dum = dum.^3;               %Diferencias al cubo
            dum = sum(dum);             %Suma de las diferencias al cubo
            m3 = dum/length(Data_ArtRem(:,4));         %Momento de orden 3
            CAFc4 = m3/(desvEstandar(4)^3);
            %skewness(x)

            % Coeficiente de Pearson
            CAPc3= (media(3)-moda(3))/desvEstandar(3);
            CAPc4= (media(4)-moda(4))/desvEstandar(4);

            %Coeficiente de Bowleyq
            y = sort(Data_ArtRem(:,:));
            Q_1 = median(y(find(y<median(y))));
            Q_2 = median(y);
            Q_3 = median(y(find(y>median(y))));

            CAB = ( Q_3+Q_1-2*mediana )/( Q_3-Q_1 );

            % Valor absoluto medio
            for j=1:length(Data_ArtRem(:,:))
                MAV = MAV+abs(Data_ArtRem(j,:));
            end
            MAV = MAV/length(Data_ArtRem(:,:));

            % Características de señal ERD-ERS

            % Calcular la media
            mediaER = mean(Data_ER(:,:));
            % Calcular la moda
            modaER = mode(Data_ER(:,:));
            % Calcular la mediana
            medianaER = median(Data_ER(:,:));
            % Desviación estandar
            desvEstandarER = std(Data_ER(:,:));
            % Varianza
            varianzaER = var(Data_ER(:,:));
            % Maximo y mínimo
            maximoER = max(Data_ER(:,:));
            minimoER = min(Data_ER(:,:));
            % Calcular Raiz Cuadrada Media (RMS)
            RMSER = rms(Data_ER(:,:));
            % Potencia
            x_tER = Data_ER(:,:).*Data_ER(:,:);
            potenciaER = (sum(x_tER))/(2*length(Data_ER(:,:)) + 1);
            %Coeficiente de Fisher
            dum = Data_ER(:,3) - mediaER(3);            %Diferencias respecto a la media
            dum = dum.^3;               %Diferencias al cubo
            dum = sum(dum);             %Suma de las diferencias al cubo
            m3 = dum/length(Data_ER(:,3));         %Momento de orden 3
            CAFc3ER = m3/(desvEstandarER(3)^3);

            dum = Data_ER(:,4) - mediaER(4);            %Diferencias respecto a la media
            dum = dum.^3;               %Diferencias al cubo
            dum = sum(dum);             %Suma de las diferencias al cubo
            m3 = dum/length(Data_ER(:,4));         %Momento de orden 3
            CAFc4ER = m3/(desvEstandarER(4)^3);
            %skewness(x)

            % Coeficiente de Pearson
            CAPc3ER= (mediaER(3)-modaER(3))/desvEstandarER(3);
            CAPc4ER= (mediaER(4)-modaER(4))/desvEstandarER(4);

            %Coeficiente de Bowleyq
            y = sort(Data_ER(:,:));
            Q_1 = median(y(find(y<median(y))));
            Q_2 = median(y);
            Q_3 = median(y(find(y>median(y))));

            CABER = ( Q_3+Q_1-2*medianaER )/( Q_3-Q_1 );

            % Valor absoluto medio
            for j=1:length(Data_ER(:,:))
                MAVER = MAVER+abs(Data_ER(j,:));
            end
            MAVER = MAVER/length(Data_ER(:,:));

            charVecC3(:) = [media(3), moda(3), mediana(3), desvEstandar(3), varianza(3), maximo(3), minimo(3), RMS(3), potencia(3), CAFc3, CAPc3, CAB(3), MAV(3), mediaER(3), modaER(3), medianaER(3), desvEstandarER(3), varianzaER(3), maximoER(3), minimoER(3), RMSER(3), potenciaER(3), CAFc3ER, CAPc3ER, CABER(3), MAVER(3)];
            charVecC4(:) = [media(4), moda(4), mediana(4), desvEstandar(4), varianza(4), maximo(4), minimo(4), RMS(4), potencia(4), CAFc4, CAPc4, CAB(4), MAV(4), mediaER(4), modaER(4), medianaER(4), desvEstandarER(4), varianzaER(4), maximoER(4), minimoER(4), RMSER(4), potenciaER(4), CAFc4ER, CAPc4ER, CABER(4), MAVER(4)];

            charVec = cat(2,charVecC3,charVecC4);
            charVec = rescale(charVec,-1,1,'InputMin',minCV,'InputMax',maxCV);

            round(net.predict(charVec))
            
            % Graficar señal
            plot(Data_ArtRem)
            drawnow;
        end

        i=i+1;
        if i >= 50000
            break
        end
    end

end
