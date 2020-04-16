function pbl05_SmartPersistance()
clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])


%% Smart Persistance à 2h

AJO = load('filledTablesAjaccio');
ODE = load('filledTablesOdeillo.mat');

timeSteps = 5:5:30;
maxHorizon  = 2*60;
modelList = {'ARMA'};


if ~exist('pbl05_Results2h.mat','file')
    AJO_metrics = train_and_forecast(AJO);
    ODE_metrics = train_and_forecast(ODE);
    save('pbl05_Results2h.mat')
else
    load('pbl05_Results2h.mat');
end

otherModels = load('pbl03_results.mat');

figure(1), clf
plot_results(AJO_metrics), hold all
set(gca, 'ColorOrderIndex',2);
plot_results(otherModels.AJO_metrics(1,:))
legend off
title('Ajaccio')

figure(2), clf
plot_results(ODE_metrics), hold all
set(gca, 'ColorOrderIndex',2);
plot_results(otherModels.ODE_metrics(1,:))
legend off
title('Odeillo')


%%% 
% Bonne nouvelle, l'ARMA (rouge) est meilleur que la SP (bleu) !! On
% retrouve quand même la même allure et le fait qu'Ajaccio soit mieux
% qu'Odeillo (pour la facilité de prévision)
   


%% Smart Persistance à 6h
timeSteps = 5:5:60;
maxHorizon  = 6*60;
modelList = {'ARMA'};

if ~exist('pbl05_Results6h.mat','file')
    AJO_metrics = train_and_forecast(AJO);
    ODE_metrics = train_and_forecast(ODE);
    save('pbl05_Results6h.mat')
else
    load('pbl05_Results6h.mat');
end

otherModels.AJO = load('pbl04_ResultsAJO.mat');
otherModels.ODE = load('pbl04_ResultsODE.mat');

figure(1), clf
plot_results(AJO_metrics), hold all
set(gca, 'ColorOrderIndex',2);
plot_results(otherModels.AJO.metrics)
legend off
xticks(0:60:6*60)
title('Ajaccio')

figure(2), clf
plot_surface(otherModels.AJO.fmList, AJO_metrics)
title('Ajaccio')


figure(3), clf
plot_results(ODE_metrics), hold all
set(gca, 'ColorOrderIndex',2);
plot_results(otherModels.ODE.metrics)
legend off
xticks(0:60:6*60)
title('Odeillo')

figure(4), clf
plot_surface(otherModels.ODE.fmList, ODE_metrics)
title('Odeillo')

%% Fonctions
 function metrics = train_and_forecast(LOC)
        metrics = cell(length(modelList),length(timeSteps));
        for i = 1:length(modelList)
            fmList(1,:) = train_models(LOC.filledTableTrain, modelList{i}, LOC.fm1);
            
            for j = 1:length(fmList)
                fm = fmList(j);
                % Calcul complet pour faire les erreurs à la main. Long à cause du fillGaps
                fm.isTrained = true;
                fm.modelType = 'SP';
                [timePred, GiPred, GiMeas, isFilled, avgTable] = fm.forecast_full(LOC.filledTableForecast);
                GiMeas(isFilled) = NaN;
                GiPred(isFilled) = NaN;
                metrics{i,j} = fm.get_metrics(GiMeas, GiPred);
                save('pbl03_results_temp.mat', 'metrics')
            end
        end
    end

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
            fmList(j) = forecastModel([], modelType, opts,...
                'plot'                  , false                             , ...
                'fillGaps'              , false                             , ...
                'gapInterpolationLimit' , modelTemplate.cleanPara.interpolation_limit , ...
                'gapPersistenceLimit'   , modelTemplate.cleanPara.persistence_limit   , ...
                'gapClearskyLimit'      , modelTemplate.cleanPara.clearsky_limit      , ...
                'nightBehaviour'        , modelTemplate.nightBehaviour                , ...
                'verbose'               , true ,...
                'train', false);
            toc
        end
    end
    function plot_results(metrics)
        col = lines;
        for iTS = 1:size(metrics,2)
            for iModel = 1:size(metrics,1)
                m = metrics{iModel,iTS};
                steps = timeSteps(iTS)*(1:ceil(maxHorizon/timeSteps(iTS)));
                
                h(iModel, iTS) = plot3(steps,...
                    repmat(timeSteps(iTS),length(steps),1),...
                    m{6,2:end}*100, '.-', ...
                    'DisplayName', modelList{iModel});
                set(gca, 'ColorOrderIndex', get(gca, 'ColorOrderIndex') - 1); 
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


  function plot_surface(fmList, metrics)
        rmse = metrics{1}{6,2:end};
        steps0 = (1:fmList(1).Npred)*fmList(1).timeStep;
        timesteps = [fmList.timeStep];
        
        for i = 2:length(metrics)
            err = metrics{i}{6,2:end};
            steps = (1:fmList(i).Npred)*fmList(i).timeStep;
            err_interp = interp1(steps, err, steps0);
            rmse = [rmse ; err_interp];
        end
        
        rmse(rmse>1)=NaN;
        
        surf(steps0, timesteps, rmse*100), hold all
        contourf(steps0, timesteps, rmse*100)
        zlabel('nRMSE')
        zlim([0 65])
        xlabel('Horizon')
        xticks(0:60:max(xlim))
        ylabel('TimeStep')
        grid on
    end


end