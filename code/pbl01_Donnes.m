%% Donn�es m�t�o
% Importation des donn�es m�t�o et v�rification avec le clearsky. Les
% donn�es sont ensuite pass�s dans un forecastModel, juste pour r�cup�rer
% la table nettoy�e et remplie avec |fill_gaps| . Comme �a prend un peu de
% temps, je fait �a en amont et je sauvegarde les tables propres.

%%
function pbl01_Donnes()
close all
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])

%% Donnees Ajaccio
load(fullfile(userpath, 'Data', 'Ajaccio', '2015-2018_1min.mat'));

% Pour reshape
data(1:60,:) = [];
data(2102401:end,:)=[];

% Mise en forme commune
data = removevars(data,{'VentDir_deg', 'VentVit_ms', 'Temp_C', 'Diffus_Wm2', 'Global60_Wm2', 'Global45_Wm2'});
data.Properties.VariableNames = {'Irradiance'};

% V�rification du CS
solis = donnes_solis();
verif_CS(data, solis.ajaccio)

% Affichage d'un jour
figure(1)
xlim(datetime(2015,07,[03 04], 'TimeZone', 'UTC'))
snapnow;

%%%
% Les donn�es ont l'air synchro avec le clearsky (heures en UTC bien sur).
% Par contre � partir de D�cembre 2017, la valeur mesur�e chute !
% Bizarrement cela correspond � la date � laquelle on a ajout� la mesure du
% global � 30�. Probablement du � un d�calage de colonne dans le fichier
% txt. Pour le moment je ne vais pas prendre de donn�es apres 2018 pour
% �tre sur.

%% Donnees Ajaccio tronqu�es
data(1533601:end,:)=[]; % Retrait apres 2017-12-01

verif_CS(data, solis.ajaccio)
prepare_tables(data, solis.ajaccio, 'filledTablesAjaccio.mat')

%% Donn�es Odeillo
% Pour Odeillo, il y avait un soucis avec les heures. Pour recaler en UTC
% j'ai du ajouter 1h � ce qui �tait enregistr�, d�finir �a comme l'heure
% locale fran�aise puis revenir � UTC. L� �a a l'air synchro. Et il y avait
% aussi beaucoup de trous dans le .mat que j'avais r�cup�r� donc j'ai du
% refaire toute l'importation. C'est pour �a que les r�sultats Odeillo sont
% tr�s diff�rents. On a beaucoup plus de donn�es maintenant.
clearvars data
rawData = load([userpath '\Data\Donn�es odeillo\Odeillo_UTC.mat']);
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
figure(1)
xlim(datetime(2001,10,[01 02], 'TimeZone', 'UTC'))
snapnow;

prepare_tables(data, solis.odeillo, 'filledTablesOdeillo.mat')


%% Exemple de donn�es d�cal�es
% Pour comparaison, �a donne �a si les mesures sont d�cal�s dans le temps.
% J'ai volontairement ajout� 30 minutes pour d�caler le clearsky. Le Kt
% n'est plus homog�ne : plus sombre en d�but de journ�e et plus brillant �
% la fin. A comparer avec celui obtenu qui lui para�t homog�ne
data.Time = data.Time + minutes(30);
verif_CS(data, solis.odeillo)


%% V�rif du clearsky
% Pour v�rifier la qualit� des donn�es, je compare avec le ClearSky.

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
        
        figure(2), clf, hold all
        h = pcolor(years(T2(1,:)-T2(1,1)), hours(T2(:,1)-T2(1,1)), K2);
        set(h, 'EdgeColor', 'none')
        colormap(hot)
        grid on
        xlabel('Ann�es')
        ylabel('Heures')
        snapnow;
    end

%% Prepare tables
% On fait passer les donn�es dans un mod�le. Les seuls param�tres
% importants sont ceux li�s � fillGaps. |nightBehaviour| n'influe pas non
% plus. On utilise une ann�e pour l'entrainement et 2 pour les tests.

    function prepare_tables(data, solisOpts, matName)
        if ~exist(matName, 'file')
            opts.solisOpts=solisOpts;
            opts.timeStep = 1;
            opts.sunHeightLim = 5;
            opts.Nhist = 1;
            opts.Npred = 1;
            opts.Nskip = 0;
            
            % Pr�paration de la table pour l'entrainement
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
            
            
            % Pr�paration de la table pour les tests
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


end

