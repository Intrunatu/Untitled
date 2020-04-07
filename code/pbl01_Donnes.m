%% Resultats
%
% L'objectif est de tracer la nRMSE en fonction de l'horizon et du pas de
% temps du modèle. Comme les données sont moyénées avec ce pas de temps,

%%
function pbl01_Donnes()
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])

%% Vérif du clearsky
% Pour vérifier la qualité des données, je compare avec le ClearSky.

    function verif_CS(data, solisOpts)
        % Calcul du ClearSky, Kt et suppression des nuits
        [ClearSky, SunHeight] = bb_solis(data.Time,solisOpts);
        Kt = data.Irradiance./ClearSky;
        Kt(SunHeight<5) = NaN;
        
        % Passage en matrice
        T2 = reshape(data.Time, 24*60, []);
        K2 = reshape(Kt, 24*60, []);
        
        figure(1), clf, hold all
        plot(data.Time, data.Irradiance)
        plot(data.Time, ClearSky)
        snapnow;
        
        clf
        h = pcolor(years(T2(1,:)-T2(1,1)), hours(T2(:,1)-T2(1,1)), K2);
        set(h, 'EdgeColor', 'none')
        colormap(hot)
        grid on
        xlabel('Années')
        ylabel('Heures')
        snapnow;
    end

%% Prepare tables
%
    function prepare_tables(data, solisOpts, matName)
        if ~exist(matName, 'file')
            opts.solisOpts=solisOpts;
            opts.timeStep = 1;
            opts.sunHeightLim = 5;
            opts.Nhist = 1;
            opts.Npred = 1;
            opts.Nskip = 0;
            
            % Préparation de la table pour l'entrainement
            inputTableTrain = data(1:525600,:);            
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
            
                        
            % Préparation de la table pour les tests
            inputTableForecast = data(525601:end,:);
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
            
            save(matName, 'filledTableTrain', 'filledTableForecast', 'fm1')
        end
    end

%% Donnees Ajaccio
load(fullfile(userpath, 'Data', 'Ajaccio', '2015-2018_1min.mat'));

% Pour reshape
data(1:60,:) = [];
data(2102401:end,:)=[];

% Mise en forme commune
data = removevars(data,{'VentDir_deg', 'VentVit_ms', 'Temp_C', 'Diffus_Wm2', 'Global60_Wm2', 'Global45_Wm2'});
data.Properties.VariableNames = {'Irradiance'};


solis = donnes_solis();
verif_CS(data, solis.ajaccio)

%%%
% Les données ont l'air synchro avec le clearsky (heures en UTC bien sur).
% Par contre à partir de Décembre 2017, la valeur mesurée chute !
% Bizarrement cela correspond à la date à laquelle on a ajouté la mesure du
% global à 30°. Probablement du à un décalage de colonne dans le fichier
% txt. Pour le moment je ne vais pas prendre de données apres 2018 pour
% être sur.

%% Donnees Ajaccio tronquées
data(1533601:end,:)=[]; % Retrait apres 2017-12-01

verif_CS(data, solis.ajaccio)
prepare_tables(data, solis.ajaccio, 'filledTablesAjaccio.mat')

%% Données Odeillo
clearvars data
rawData = load([userpath '\Data\Données odeillo\Odeillo_UTC.mat']);
data = timetable(rawData.data.Time, rawData.data.GHI);
clearvars rawData
data.Properties.VariableNames={'Irradiance'};
data(isnat(data.Time),:)=[];
data.Irradiance(data.Irradiance<0,:) = 0;

% Pour pouvoir faire le reshape
data.Irradiance(end+1) = 0;
data.Time(end) = dateshift(data.Time(end-1), 'end', 'year')+days(1);
data = retime(data, 'minutely');
data(end,:) = [];

verif_CS(data, solis.odeillo)

prepare_tables(data, solis.odeillo, 'filledTablesOdeillo.mat')


%% Exemple de données décalées
% Pour comparaison, ça donne ça si les mesures sont décalés dans le temps.
% J'ai volontairement ajouté 30 minutes pour décaler le clearsky. Le Kt
% n'est plus homogène : plus sombre en début de journée et plus brillant à
% la fin. A comparer avec celui obtenu qui lui paraît homogène
data.Time = data.Time + minutes(30);
verif_CS(data, solis.odeillo)
close(1)

end

