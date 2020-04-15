%% Resultats à 6h
% Les résultats sont à peu pres les même pour tous les modèles à 2h donc
% pour 6h je n'utilise qu'ARMA (le plus rapide)
% 

%% Effet de l'horizon max
function pbl04_Resultats_6h()
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
close all

AJO = load('filledTablesAjaccio');
ODE = load('filledTablesOdeillo');

if true
    fm_1h = train_models(AJO.filledTableTrain, 'ARMA', AJO.fm1, 10, 120);
    fm_6h = train_models(AJO.filledTableTrain, 'ARMA', AJO.fm1, 10, 60*6);
    
    m1 = get_metrics(fm_1h, AJO);
    m6 = get_metrics(fm_6h, AJO);
    
    figure(1), clf, hold all
    plot(m1{1}{6,2:end}*100, '.-')
    plot(m6{1}{6,2:end}*100, '.-')
    xlabel('Setp')
    ylabel('nRMSE [%]')
    grid on
end

%%% 
% J'ai entrainé un modèle 10 min pour 1h d'horizon max et 6h. La nRMSE
% n'est pas la même au début. Sans doute parce que je ne teste pas sur les
% mêmes points. En prennant un horizon max de 6h, il y a certaines lignes
% de la matrice |parameters| qui sautent parce qu'il y a des NaNs. Pour moi
% celle à 2h devrait être inférieure à celle de 6h puisqu'elle a été
% entrainée sur plus de points. Par contre elle est aussi testée sur plus
% de points, potentiellement en millieu de journée... A creuser !


%% Ajaccio
if ~exist('pbl04_ResultsAJO.mat','file')
    fmList = train_models(AJO.filledTableTrain, 'ARMA', AJO.fm1, 5:5:60, 60*6);
    metrics = get_metrics(fmList, AJO);
    save('pbl04_ResultsAJO.mat', 'fmList', 'metrics')
end
load('pbl04_ResultsAJO.mat', 'fmList', 'metrics')

figure
plot_results(metrics)
figure
plot_surface(fmList, metrics)

%%%
% On retrouve l'allure attendue sur Ajaccio. Pas de minimum qui ressort. En
% augmentant le timestep on gagne en nRMSE mais pas beaucoup. Ca veut dire
% que ça ne sert à rien d'augmenter le TS pour gagner en nRMSE.

%% Odeillo
if ~exist('pbl04_ResultsODE.mat','file')
    fmList = train_models(ODE.filledTableTrain, 'ARMA', ODE.fm1, 5:5:60, 60*6);
    metrics = get_metrics(fmList, ODE);
    save('pbl04_ResultsODE.mat', 'fmList', 'metrics')
end
load('pbl04_ResultsODE.mat', 'fmList', 'metrics')

figure
plot_results(metrics)
figure
plot_surface(fmList, metrics)

%%% 
% Même remarque que sur Ajaccio. En plus on a la même allure donc pas mal
% pour la généralisation. L'erreur est aussi plus importante mais on s'en
% doutait.

%% Comparaison timesteps
figure(1), clf, hold all
plot(5:5:60*6, metrics{1}{6,2:end}*100, '.-')
plot(60:60:60*6,metrics{end}{6,2:end}*100, '.-')
grid on
xlabel('Horizon [min]')
xticks(60:60:60*6)
ylabel('nRMSE [%]')
grid on

%%%
% En comparant les courbes avec les TS 10min et 1h, on voit quand même
% qu'on gagne (courbes tracées sur Odeillo)



%% Fonctions

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
        zlim([0 50])
        xlabel('Horizon')
        xticks(0:60:max(xlim))
        ylabel('TimeStep')
        grid on
    end



    function plot_results(metrics)
        clf
        col = lines;
        timeSteps = 5:5:60;
        maxHorizon = 6*60;
        for iTS = 1:size(metrics,2)
            for iModel = 1:size(metrics,1)
                m = metrics{iModel,iTS};
                steps = timeSteps(iTS)*(1:ceil(maxHorizon/timeSteps(iTS)));
                
                h(iModel, iTS) = plot3(steps,...
                    repmat(timeSteps(iTS),length(steps),1),...
                    m{6,2:end}*100, '.-', ...
                    'DisplayName', 'ARMA',...
                    'Color', col(iModel,:));
                hold all
            end
        end
        grid on
        %         legend(modelList)
        xlabel('Horizon [min]')
        ylabel('TimeStep [min]')
        zlabel('nRMSE [%]')
        xticks(0:60:max(xlim))
        zlim([0 50])
    end


    function metrics = get_metrics(fmList, LOC)
        for i = 1:numel(fmList)
            fm = fmList(i);
            [timePred, GiPred, GiMeas, isFilled, avgTable] = fm.forecast_full(LOC.filledTableForecast);
            GiMeas(isFilled) = NaN;
            GiPred(isFilled) = NaN;
            metrics{i}= fm.get_metrics(GiMeas, GiPred);
        end
    end


    function [fmList] = train_models(filledTableTrain, modelType,...
            modelTemplate, timeSteps, maxHorizon)
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
                'verbose'               , false);
            toc
        end
    end
end

