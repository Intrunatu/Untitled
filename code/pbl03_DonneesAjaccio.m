%%
% Global horizontal

clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
load(fullfile(userpath, 'Data', 'Ajaccio', '2015-2018_1min.mat'));
data(1:60,:) = [];
data(2102401:end,:)=[];

%% Verification des donnes avec ClearSky
% Pour v�rifier la qualit� des donn�es, je compare avec le ClearSky.

% Options du modele
solisOpts.phi      = 41.9167;  % latitude degre
solisOpts.lambda   =  8.7333;  % longitude degre
solisOpts.altitude = 70;       % altitude en m
solisOpts.zone     = 2;        % type d'aerosol 1=rural 2=maritime 3=urban 4=tropospherique
solisOpts.azimut   = 0;        % azimut en degr�
solisOpts.albedo   = 0.25;     % alb�do du sol
solisOpts.tilt     =  0;       % angle d'inclinaison en degre
solisOpts.oad      = 0.2;      % prof optique pour aerosol a 700nm
solisOpts.w        = 1.8;      % colonne d'eau en cm

% Calcul du ClearSky, Kt et suppression des nuits
[ClearSky, SunHeight] = bb_solis(data.Time,solisOpts);
Kt = data.Global00_Wm2./ClearSky;
Kt(SunHeight<5) = NaN;

% Passage en matrice
T2 = reshape(data.Time, 24*60, []);
K2 = reshape(Kt, 24*60, []);

figure(1), clf, hold all
plot(data.Time, data.Global00_Wm2)
plot(data.Time, ClearSky)
snapnow;

clf
h = pcolor(years(T2(1,:)-T2(1,1)), hours(T2(:,1)-T2(1,1)), K2);
set(h, 'EdgeColor', 'none')
colormap(hot)
grid on
xlabel('Ann�es')
ylabel('Heures')

%%
% Pour comparaison, �a donne �a si les mesures sont d�cal�s dans le temps.
% J'ai volontairement ajout� 30 minutes pour d�caler le clearsky. Le Kt
% n'est plus homog�ne : plus sombre en d�but de journ�e et plus brillant �
% la fin. A comparer avec celui obtenu qui lui para�t homog�ne

% Nouveau ClearSky pas bon
[ClearSky_pasBon, SunHeight] = bb_solis(data.Time+minutes(30),solisOpts);
Kt_pasBon = data.Global00_Wm2./ClearSky_pasBon;
Kt_pasBon(SunHeight<5) = NaN;
K2_pasBon = reshape(Kt_pasBon, 24*60, []);


clf
h = pcolor(years(T2(1,:)-T2(1,1)), hours(T2(:,1)-T2(1,1)), K2_pasBon);
set(h, 'EdgeColor', 'none')
colormap(hot)
grid on
xlabel('Ann�es')
ylabel('Heures')

%%
data(1533601:end,:)=[];
% Les donn�es ont l'air synchro avec le clearsky (heures en UTC bien sur).
% Par contre � partir de D�cembre 2017, la valeur mesur�e chute !
% Bizarrement cela correspond � la date � laquelle on a ajout� la mesure du
% global � 30�. Probablement du � un d�calage de colonne dans le fichier
% txt. Pour le moment je ne vais pas prendre de donn�es apres 2018 pour
% �tre sur.

%% Pr�paration des tables pour entrainement et test
opts.solisOpts=solisOpts;
opts.timeStep = 1;
opts.sunHeightLim = 5;
opts.Nhist = 1;
opts.Npred = 1;
opts.Nskip = 0;

% Pr�paration de la table pour l'entrainement
inputTableTrain.Time = data.Time(1:525601);
inputTableTrain.Irradiance = data.Global00_Wm2(1:525601);
inputTableTrain = table2timetable(struct2table(inputTableTrain));

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



% Pr�paration de la table pour les tests
inputTableForecast.Time = data.Time(525602:end);
inputTableForecast.Irradiance = data.Global00_Wm2(525602:end);
inputTableForecast = table2timetable(struct2table(inputTableForecast));

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

save('filledTablesAjaccio.mat', 'filledTableTrain', 'filledTableForecast', 'fm1')