%% Resultats

clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
load('filledTables')


timeSteps = [ 10:5:30];
% modelList = {'ARMA', 'NN', 'RF', 'SVR', 'GP'};
modelList = {'ARMA', 'NN', 'SVR'};
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
    save('pbl02_results.mat', 'metrics')
end

%% Affichage
% Le modèle SVR est meilleur que les autres. Il faut que je modifie le code
% d'entrainement des modèles parce que pour le moment, deux modèles qui
% ont le même pas de temps mais pas le meme horizon max n'ont pas les mêmes
% valeurs dans les premièrs pas de temps... Par exemple, on voit sur cette
% figure que ARMA et NN restent proches, même au pas de temps 10min. Sur la
% figure de pbl01 (calculé avec un horizon max de 6h) le NN est à l'ouest
% comparé au ARMA.
load('pbl02_results.mat')
figure(2), clf
col = lines;
for iTS = 1:size(fmList,2)
    for iModel = 1:size(fmList,1)
        m = metrics{iModel,iTS};
        steps = timeSteps(iTS)*(1:ceil(maxHoriz/timeSteps(iTS)));
        
        plot3(steps,...
            repmat(timeSteps(iTS),length(steps),1),...
            m{6,2:end}*100, '.-', ...
            'DisplayName', modelList{iModel},...
            'Color', col(iModel,:))
        hold all
    end
end
grid on
xlabel('Horizon [min]')
ylabel('TimeStep [min]')
zlabel('nRMSE [%]')
xticks(0:30:max(xlim))