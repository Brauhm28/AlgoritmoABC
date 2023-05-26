EEG.data=Data_Filtered;
EEG.srate=200;
EEG.pnts=500;   % NUMBER OF POINTS PER TRIAL
EEG.nbchan=4;
EEG.chanlocs= [];
EEG.trials=1;

OUTEEG_EOG = pop_autobsseog(EEG,wl,ws,bss_alg,bss_opt,crit_alg,crit_opt);  %Algoritmo BSS con remocion EOG
%OUTEEG_EMG = pop_autobssemg(OUTEEG_EOG,wl,ws,bss_alg,bss_opt,'emg_psd',{'ratio',10,'fs',200,'femg',15,'estimator',spectrum.welch({'Hamming'},80),'range',[0  32]});
Data_ArtRem(:,:)=OUTEEG_EOG.data';
% Graficar señal
plot(Data_ArtRem)

