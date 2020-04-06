clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])

AJO = load('filledTablesAjaccio');
ODE = load('filledTables');
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

%% Odeillo
rng(1)
opts.solisOpts=ODE.solisOpts;
ODE.fm = forecastModel(AJO.filledTableTrain, 'ARMA', opts,...
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


%% Affichage
clf, hold all
steps = AJO.fm.timeStep*(1:AJO.fm.Npred);
plot(steps, AJO.metrics{6,2:end}*100, 'DisplayName', 'Ajaccio')
plot(steps, ODE.metrics{6,2:end}*100, 'DisplayName', 'Odeillo')
xlabel('TimeStep [min]')
ylabel('nRMSE [%]')
grid on
legend show

