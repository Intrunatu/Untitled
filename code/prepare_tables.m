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
solis = donnes_solis();
opts.solisOpts = solis.odeillo;

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
