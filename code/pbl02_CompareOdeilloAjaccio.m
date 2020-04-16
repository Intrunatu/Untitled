%% Comparaison Odeillo Ajaccio
% Pour se chauffer un peu on va juste faire un modèle sur Ajaccio et un sur
% Odeillo, calculer les erreurs et comparer les résultats. Ca permet de
% voir si tout est bon avant de passer aux gros calculs.

%%
clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])

AJO = load('filledTablesAjaccio');
ODE = load('filledTablesOdeillo.mat');
modelTemplate = AJO.fm1;

% Solis 
solis = donnes_solis();
AJO.solisOpts = solis.ajaccio;
ODE.solisOpts = solis.odeillo;

opts.timeStep = 10;
opts.sunHeightLim = modelTemplate.sunHeightLim;
opts.Nhist = 12;
opts.Npred = 12;
opts.Nskip = 0;
nightBehaviour = 'deleteNightValues';


cummean = @(x) cumsum(x, 'omitnan')./cumsum(~isnan(x));
cumRMSE = @(meas,pred) sqrt(cummean((meas-pred).^2));  
cumnRMSE = @(meas,pred)  cumRMSE(meas,pred)./cummean(meas);  



%% Ajaccio
rng(1)
opts.solisOpts=AJO.solisOpts;
AJO.fm = forecastModel(AJO.filledTableTrain, 'ARMA', opts,...
    'plot'                  , false                             , ...
    'fillGaps'              , false                             , ...
    'gapInterpolationLimit' , modelTemplate.cleanPara.interpolation_limit , ...
    'gapPersistenceLimit'   , modelTemplate.cleanPara.persistence_limit   , ...
    'gapClearskyLimit'      , modelTemplate.cleanPara.clearsky_limit      , ...
    'nightBehaviour'        , nightBehaviour                , ...
    'verbose'               , false);


[timePred, GiPred, GiMeas, isFilled, avgTable] = AJO.fm.forecast_full(AJO.filledTableForecast);
GiMeas(isFilled) = NaN;
GiPred(isFilled) = NaN;
AJO.metrics = AJO.fm.get_metrics(GiMeas, GiPred);
AJO.cumnRMSE = cumnRMSE(GiMeas(:,1), GiPred(:,1));

AJO.sp = AJO.fm;
AJO.sp.modelType = 'SP';
[timePred, GiPred, GiMeas, isFilled, avgTable] = AJO.sp.forecast_full(AJO.filledTableForecast);
GiMeas(isFilled) = NaN;
GiPred(isFilled) = NaN;
AJO.metricsSP = AJO.sp.get_metrics(GiMeas, GiPred);

% TR = timerange(AJO.filledTableForecast.Time(end)-hours(36), AJO.filledTableForecast.Time(end)-hours(12));
% tblout=AJO.fm.forecast(AJO.filledTableForecast(TR,:), 'compare', 'plot', true)


%% Odeillo
rng(1)
opts.solisOpts=ODE.solisOpts;
ODE.fm = forecastModel(ODE.filledTableTrain, 'ARMA', opts,...
    'plot'                  , false                             , ...
    'fillGaps'              , false                             , ...
    'gapInterpolationLimit' , modelTemplate.cleanPara.interpolation_limit , ...
    'gapPersistenceLimit'   , modelTemplate.cleanPara.persistence_limit   , ...
    'gapClearskyLimit'      , modelTemplate.cleanPara.clearsky_limit      , ...
    'nightBehaviour'        , nightBehaviour                , ...
    'verbose'               , false);

[timePred, GiPred, GiMeas, isFilled, avgTable] = ODE.fm.forecast_full(ODE.filledTableForecast);
GiMeas(isFilled) = NaN;
GiPred(isFilled) = NaN;
ODE.metrics = ODE.fm.get_metrics(GiMeas, GiPred);
ODE.cumnRMSE = cumnRMSE(GiMeas(:,1), GiPred(:,1));

ODE.sp = ODE.fm;
ODE.sp.modelType = 'SP';
[timePred, GiPred, GiMeas, isFilled, avgTable] = ODE.sp.forecast_full(ODE.filledTableForecast);
GiMeas(isFilled) = NaN;
GiPred(isFilled) = NaN;
ODE.metricsSP = ODE.sp.get_metrics(GiMeas, GiPred);


%% Affichage
figure(1)
clf, hold all
steps = AJO.fm.timeStep*(1:AJO.fm.Npred);
plot(steps, AJO.metrics{6,2:end}*100, 'DisplayName', 'Ajaccio')
set(gca, 'ColorOrderIndex',1)
plot(steps, AJO.metricsSP{6,2:end}*100, '--', 'DisplayName', 'Ajaccio SP')
plot(steps, ODE.metrics{6,2:end}*100, 'DisplayName', 'Odeillo')
set(gca, 'ColorOrderIndex',2)
plot(steps, ODE.metricsSP{6,2:end}*100, '--', 'DisplayName', 'Odeillo SP')
xlabel('TimeStep [min]')
ylabel('nRMSE [%]')
grid on
legend show

figure(2)
clf, hold all
plot(AJO.cumnRMSE*100, 'DisplayName', 'Ajaccio')
plot(ODE.cumnRMSE*100, 'DisplayName', 'Odeillo')
xlabel('Points []')
ylabel('nRMSE [%]')
grid on
legend show

%%%
% Cette fois ci comme prévu on a Odeillo qui a un moins bon RMSE
% qu'Ajaccio. Du coup 40% nRMSE à 2h c'est beaucoup !! Et je ne comprends
% toujours pas pourquoi avec plein de trous dans les données on avait une
% meilleure nRMSE.
% J'ai rajouté une figure pour la convergence de la nRMSE. On voit qu'on a
% convergé donc c'est bon.
