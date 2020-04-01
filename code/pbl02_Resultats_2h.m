%% Resultats tout mod�les 2h
% M�me objectif que pr�c�demment mais avec tout les mod�les. Ceratains
% prennent trop de temps (RF et GP) donc j'ai r�duit � 2h pour l'horizon
% max et 10min pour le pas de temps mini.
%
% Options des mod�les : 
% 
% * 2h historique
% * 2h predictions
% * pas de saut avant 1ere mesure
% * Lignes contenant une nuit ($h>5^\circ$) supprim�es
%
% 

%%%
clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
load('filledTables')


timeSteps = 10:5:30;
modelList = {'ARMA', 'NN', 'RF', 'SVR', 'GP'};
maxHoriz = 2*60;

%% Calculs
% Prend trop de temps � faire � chaque fois. Les r�sultats sont
% sauvegard�s. Pour RF et GP, cela prend trop de place sur le disque
% (plusieurs Go !!!) donc ils sautent.
if false
    for i = 1:length(modelList)        
        fmList(i,:) = train_models(filledTableTrain, modelList{i}, fm1, timeSteps, maxHoriz);
    end
    
    
    metrics = cell(size(fmList));
    for i =1:numel(fmList)
        disp(i)
        fm = fmList(i);
        % Calcul complet pour faire les erreurs � la main. Long � cause du fillGaps
        [timePred, GiPred, GiMeas, isFilled, avgTable] = fm.forecast_full(filledTableForecast);
        GiMeas(isFilled) = NaN;
        GiPred(isFilled) = NaN;
        metrics{i} = fm.get_metrics(GiMeas, GiPred);
    end
    save('pbl02_results.mat', 'metrics')
end

%% Affichage
load('pbl02_results.mat')
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
% Le mod�le SVR est meilleur que les autres. Il faut que je modifie le code
% d'entrainement des mod�les parce que pour le moment, deux mod�les qui
% ont le m�me pas de temps mais pas le meme horizon max n'ont pas les m�mes
% valeurs dans les premi�rs pas de temps... Par exemple, on voit sur cette
% figure que ARMA et NN restent proches, m�me au pas de temps 10min. Sur la
% figure de pbl01 (calcul� avec un horizon max de 6h) le NN est � l'ouest
% compar� au ARMA.