clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
delete('fmARMA*.mat')

% Données météo
rawData = load([userpath '\Data\Données odeillo\Odeillo_UTC.mat']);
inputTable = timetable(rawData.table.TimeUTC, rawData.table.GHI);
clearvars rawData
inputTable.Properties.VariableNames={'Irradiance'};
inputTable(isnat(inputTable.Time),:)=[];
inputTable(inputTable.Irradiance<0,:) = [];

inputTableTrain=inputTable(5113147:5638657,:); % Du 01/01/14 au 01/01/15
inputTableForecast=inputTable(5638657:end,:); % Du 01/01/15 au 18/10/16


% Options du modele
solisOpts.phi      = 42.497;   % latitude degre
solisOpts.lambda   =  2.030;   % longitude degre
solisOpts.altitude = 1650;     % altitude en m
solisOpts.zone     = 2;        % type d'aerosol 1=rural 2=maritime 3=urban 4=tropospherique
solisOpts.azimut   = 1.63;     % azimut en degré
solisOpts.albedo   = 0.25;     % albédo du sol
solisOpts.tilt     = 30;       % angle d'inclinaison en degre
solisOpts.oad      = 0.2;      % prof optique pour aerosol a 700nm
solisOpts.w        = 1.8;      % colonne d'eau en cm
opts.solisOpts=solisOpts;

opts.timeStep = 1;
opts.sunHeightLim = 5;

opts.Nhist = 1;
opts.Npred = 1;
opts.Nskip = 0;

disp('Train table')
tic
rng(1)
[fm1, filledTableTrain] = forecastModel(inputTableTrain, 'ARMA', opts,...
    'plot'                  , false     , ...
    'fillGaps'              , true      , ...
    'gapInterpolationLimit' , 5         , ...
    'gapPersistenceLimit'   , 30        , ...  % n'utilise pas la persistance
    'gapClearskyLimit'      , 30        , ...
    'nightBehaviour'        , 'deleteNightValues' , ...
    'verbose'               , false);
toc

disp('Test table')
tic
rng(1)
[fm2, filledTableForecast] = forecastModel(inputTableForecast, 'ARMA', opts,...
        'plot'                  , false                             , ...
        'fillGaps'              , true                              , ...
        'gapInterpolationLimit' , fm1.cleanPara.interpolation_limit , ...
        'gapPersistenceLimit'   , fm1.cleanPara.persistence_limit   , ...
        'gapClearskyLimit'      , fm1.cleanPara.clearsky_limit      , ...
        'nightBehaviour'        , fm1.nightBehaviour                , ...
        'verbose'               , false);
toc

save('filledTables.mat', 'filledTableTrain', 'filledTableForecast', 'fm1')
