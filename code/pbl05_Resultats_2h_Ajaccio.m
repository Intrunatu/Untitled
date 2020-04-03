%% Resultats tout modèles 2h
% Même objectif que précédemment mais avec tout les modèles. Ceratains
% prennent trop de temps (RF et GP) donc j'ai réduit à 2h pour l'horizon
% max et 10min pour le pas de temps mini.
%
% Options des modèles :
%
% * 2h historique
% * 2h predictions
% * pas de saut avant 1ere mesure
% * Lignes contenant une nuit ($h>5^\circ$) supprimées
%
%

%%%
clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
load('filledTablesAjaccio')


timeSteps = 10:5:30;
modelList = {'ARMA', 'NN', 'RF', 'SVR', 'GP'};
maxHoriz = 2*60;

%% Calculs
% Prend trop de temps à faire à chaque fois. Les résultats sont
% sauvegardés. Pour RF et GP, cela prend trop de place sur le disque
% (plusieurs Go !!!) donc ils sautent.
if false
    for i = 1:length(modelList)
        fmList(i,:) = train_models(filledTableTrain, modelList{i}, fm1, timeSteps, maxHoriz);
    end
    
    
    metrics = cell(size(fmList));
    for i =1:numel(fmList)
        disp(i)
        fm = fmList(i);
        % Calcul complet pour faire les erreurs à la main. Long à cause du fillGaps
        [timePred, GiPred, GiMeas, isFilled, avgTable] = fm.forecast_full(filledTableForecast);
        GiMeas(isFilled) = NaN;
        GiPred(isFilled) = NaN;
        metrics{i} = fm.get_metrics(GiMeas, GiPred);
    end
    save('pbl05_results_AJO.mat', 'metrics')
end

%% Affichage
load('pbl05_results_AJO.mat')
figure(2), clf
col = lines;
for iTS = 1:size(metrics,2)
    for iModel = 1:size(metrics,1)
        m = metrics{iModel,iTS};
        steps = timeSteps(iTS)*(1:ceil(maxHoriz/timeSteps(iTS)));
        
        h(iModel, iTS) = plot3(steps,...
            repmat(timeSteps(iTS),length(steps),1),...
            m{6,2:end}*100, '.-', ...
            'DisplayName', modelList{iModel},...
            'Color', col(iModel,:));
        hold all
    end
end
grid on
legend(modelList)
xlabel('Horizon [min]')
ylabel('TimeStep [min]')
zlabel('nRMSE [%]')
xticks(0:30:max(xlim))

snapnow;
set(h(2,:), 'Visible', 'off')
set(h(5,:), 'Visible', 'off')

%%%



%% Ajaccio 6h
if false
    fmList = train_models(filledTableTrain, 'ARMA', fm1, 5:5:60, 6*60);
    save(sprintf("fmArray_%s_6h_AJO", fmList(1).modelType), 'fmList')
    
    results = calc_results(fmList,filledTableForecast);
    save(sprintf("results_%s_6h_AJO", fmList(1).modelType), 'results')
else
    load('results_ARMA_6h_AJO')
end

% Affichage en ligne
figure(1), clf
for i = 1:length(results)
    r  = results{i};    % Matrice des resultats
    dt = r(:,1);        % Timestep
    t  = r(:,2);        % Horizon de pred
    rmse = r(:,3);      % Erreur
    plot3(t, dt, rmse, '.-'), hold all
end
zlabel('nRMSE')
xlabel('Horizon')
xticks(0:60:max(xlim))
ylabel('TimeStep')
zlim([0 0.5])
grid on