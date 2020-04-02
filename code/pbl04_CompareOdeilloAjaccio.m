clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])

AJO = load('filledTablesAjaccio');
ODE = load('filledTables');
modelTemplate = AJO.fm1;

% Solis AJACCIO
AJO.solisOpts.phi      = 41.9167;  % latitude degre
AJO.solisOpts.lambda   =  8.7333;  % longitude degre
AJO.solisOpts.altitude = 70;       % altitude en m
AJO.solisOpts.zone     = 2;        % type d'aerosol 1=rural 2=maritime 3=urban 4=tropospherique
AJO.solisOpts.azimut   = 0;        % azimut en degré
AJO.solisOpts.albedo   = 0.25;     % albédo du sol
AJO.solisOpts.tilt     =  0;       % angle d'inclinaison en degre
AJO.solisOpts.oad      = 0.2;      % prof optique pour aerosol a 700nm
AJO.solisOpts.w        = 1.8;      % colonne d'eau en cm

% Solis ODEILLO
ODE.solisOpts.phi      = 42.497;   % latitude degre
ODE.solisOpts.lambda   =  2.030;   % longitude degre
ODE.solisOpts.altitude = 1650;     % altitude en m
ODE.solisOpts.zone     = 2;        % type d'aerosol 1=rural 2=maritime 3=urban 4=tropospherique
ODE.solisOpts.azimut   = 1.63;     % azimut en degré
ODE.solisOpts.albedo   = 0.25;     % albédo du sol
ODE.solisOpts.tilt     = 30;       % angle d'inclinaison en degre
ODE.solisOpts.oad      = 0.2;      % prof optique pour aerosol a 700nm
ODE.solisOpts.w        = 1.8;      % colonne d'eau en cm



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

