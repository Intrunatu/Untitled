%% Résultats 2h
% Sur ce script je compare les différents modèles sur 2h avec des pas de
% temps de 5 min à 30 min. J'ai enlevé les GP, ça prennait trop de temps
% ...

function pbl03_Resultats_2h()
%% Comparaison des modeles
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])

AJO = load('filledTablesAjaccio');
ODE = load('filledTablesOdeillo.mat');

timeSteps = 5:5:30;
modelList = {'ARMA', 'NN', 'RF', 'SVR'};
maxHorizon  = 2*60;

if ~exist('pbl03_results.mat', 'file')
    AJO_metrics = train_and_forecast(AJO);
    save('pbl03_results.mat', 'AJO_metrics')
    ODE_metrics = train_and_forecast(ODE);
    save('pbl03_results.mat', 'AJO_metrics', 'ODE_metrics')
end
load('pbl03_results.mat')

figure(1)
plot_results(AJO_metrics)
title("Ajaccio")

figure(2)
plot_results(ODE_metrics)
title("Odeillo")

%%%
% On a à peu pres les mêmes résultats pour les 4 modèles et la même allure
% pour les deux sites. On dirait bien qu'on a les résultats attendus : plus
% on augmente l'horizon, plus on augmente l'erreur et plus on augmente le
% timestep, plus on diminue l'erreur grâce au moyennage.

%% Fonctions
    function [fmList] = train_models(filledTableTrain, modelType,...
            modelTemplate)
        opts.solisOpts=modelTemplate.solisOpts;
        for j = 1:length(timeSteps)
            dt = timeSteps(j);
            disp([dt maxHorizon/dt])
            
            opts.timeStep = dt;
            opts.sunHeightLim = modelTemplate.sunHeightLim;
            
            opts.Nhist = ceil(maxHorizon/dt);
            opts.Npred = ceil(maxHorizon/dt);
            opts.Nskip = 0;
            
            tic
            rng(1)
            fmList(j) = forecastModel(filledTableTrain, modelType, opts,...
                'plot'                  , false                             , ...
                'fillGaps'              , false                             , ...
                'gapInterpolationLimit' , modelTemplate.cleanPara.interpolation_limit , ...
                'gapPersistenceLimit'   , modelTemplate.cleanPara.persistence_limit   , ...
                'gapClearskyLimit'      , modelTemplate.cleanPara.clearsky_limit      , ...
                'nightBehaviour'        , modelTemplate.nightBehaviour                , ...
                'verbose'               , true);
            toc
        end
    end

    function metrics = train_and_forecast(LOC)
        metrics = cell(length(modelList),length(timeSteps));
        for i = 1:length(modelList)
            fmList(1,:) = train_models(LOC.filledTableTrain, modelList{i}, LOC.fm1);

            for j = 1:length(fmList)
                fm = fmList(j);
                % Calcul complet pour faire les erreurs à la main. Long à cause du fillGaps
                [timePred, GiPred, GiMeas, isFilled, avgTable] = fm.forecast_full(LOC.filledTableForecast);
                GiMeas(isFilled) = NaN;
                GiPred(isFilled) = NaN;
                metrics{i,j} = fm.get_metrics(GiMeas, GiPred);
                save('pbl03_results_temp.mat', 'metrics')
            end
        end
        
        

    end

    function plot_results(metrics)
        clf
        col = lines;
        for iTS = 1:size(metrics,2)
            for iModel = 1:size(metrics,1)
                m = metrics{iModel,iTS};
                steps = timeSteps(iTS)*(1:ceil(maxHorizon/timeSteps(iTS)));
                
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
    end
end

