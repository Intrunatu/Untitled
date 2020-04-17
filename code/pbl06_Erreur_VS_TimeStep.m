%% test

function pbl06_Erreur_VS_TimeStep()
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
colors = lines;

AJO.results = load('pbl04_ResultsAJO.mat', 'fmList', 'metrics');
ODE.results = load('pbl04_ResultsODE.mat', 'fmList', 'metrics');


[AJO.steps0, AJO.timesteps, AJO.rmse] = ...
    interp_results(AJO.results.fmList, AJO.results.metrics);

[ODE.steps0, ODE.timesteps, ODE.rmse] = ...
    interp_results(ODE.results.fmList, ODE.results.metrics);


%% Interpolation lineaire
figure(1)
r = fit_results(AJO, 'poly1');
title('Ajaccio')

disp(r.Properties.Description)
disp('Ajaccio')
disp(r)

figure(2)
r = fit_results(ODE, 'poly1');
title('Odeillo')
disp('Odeillo')
disp(r)

%%%
% 
% *Ca ne vous paraït pas bizarre que pour Ajaccio et Odeillo, ce sont
% _EXACTEMENT_ les mêmes lignes juste en décallé ?*


%% Interpolation quadratique
figure(1)
r = fit_results(AJO, 'poly2');
title('Ajaccio')

disp(r.Properties.Description)
disp('Ajaccio')
disp(r)

figure(2)
r = fit_results(ODE, 'poly2');
title('Odeillo')
disp('Odeillo')
disp(r)


%% Fonctions

    function results = fit_results(LOC, fitType)
        ID = 12:12:72;
        gcf; clf; hold all;
        results = [];
        for i = 1:length(ID)            
            [f, gof] = fit(LOC.timesteps',LOC.rmse(:,ID(i))*100, fitType);
            h = plot(f, LOC.timesteps, LOC.rmse(:,ID(i))*100);
            h(1).Color = brighten(colors(i,:), -0.8);
            h(2).Color = colors(i,:);
            set(get(get(h(1),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
            
            oneLine = [ LOC.steps0(ID(i)), ...
                coeffvalues(f), ...
                gof.rsquare];
            results = [results; oneLine];            
        end
        
        results = array2table(results, 'VariableNames', ...
            ['Horizon', coeffnames(f)', 'R2']);
        results.Properties.Description = formula(f);
        
        grid on
        xlabel('Horizon [min]')
        ylabel('nRMSE [%]')
        
        labels= cellstr(num2str(LOC.steps0(ID)'));
        labels = cellfun(@(s) strcat(s, ' min'), labels, 'UniformOutput', false);
        legend(labels)
        legend('Location', 'sw')
    end



    function [steps0, timesteps, rmse] = interp_results(fmList, metrics)
        rmse = metrics{1}{6,2:end};
        steps0 = (1:fmList(1).Npred)*fmList(1).timeStep;
        timesteps = [fmList.timeStep];
        for i = 2:length(metrics)
            err = metrics{i}{6,2:end};
            steps = (1:fmList(i).Npred)*fmList(i).timeStep;
            err_interp = interp1(steps, err, steps0);
            rmse = [rmse ; err_interp];
        end
    end
end