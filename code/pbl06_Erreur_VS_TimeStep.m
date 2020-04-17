%% Erreur Vs. TimeStep
%
%
%%%
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
% Voir <#6 plus bas> pour comparaison
%
% Au final ce n'est pas vraiment linéaire. Plus sur Ajaccio que Odeillo. Le
% plus rentable reste à horizon 60min où on gagne 1.2% (1.8 pour Odeillo) à
% chaque fois qu'on augmente le timestep de 10min.


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

%%%
% Avec un poly du 2eme degré on a un meilleur R2, toujours au dessus de
% 0.96. Par contre 'physiquement' je ne sais pas si ça a un sens ...
% En fait on trace le compromis entre la résolution (TimeStep) et la
% précision (nRMSE). Ca ressemble à un Front de Pareto d'où l'idée de
% tester en 1/x.


%% Interpolation rationnelle
figure(1)
r = fit_results(AJO, 'rat01', [3000 200]);
title('Ajaccio')

disp(r.Properties.Description)
disp('Ajaccio')
disp(r)

figure(2)
r = fit_results(ODE, 'rat01', [3000 200]);
title('Odeillo')
disp('Odeillo')
disp(r)

%%%
% Bon ce n'était pas une bonne idée... on perd en R2. On aurait pu dire,
% avec $\varepsilon$ l'erreur et $dt$ le timestep :
% 
% $$\varepsilon = \frac{p_1}{dt + q_1}$$
%
% $$\varepsilon . (dt + q_1) = cste$$
% 
% En plus les bornes des coefficients trouvés sont énormes donc assez peu
% confiance en ce fit...


%% Comparaison
%

gcf; clf; hold all;
K = mean( AJO.rmse(:,12)./ODE.rmse(:,12));

plot(5:5:60, AJO.rmse(:,12), 'DisplayName', 'Ajaccio')
plot(5:5:60, ODE.rmse(:,12)*K, 'DisplayName', 'Odeillo*K')
xlabel('TimeStep [min]')
ylabel('nRMSE [%]')
title(sprintf('K = %.3f', K))
grid on
legend show

for i = 1:12    
   if 60/i/5 == round(60/i/5)       
       points(i,1) = i*5;
       points(i,2) = AJO.rmse(i,12);
   end
end
points(points(:,1) == 0 ) = NaN;
scatter(points(:,1), points(:,2), 'fill')

%%%
% Les courbes sur Ajaccio et Odeillo avaient l'air identiques à un facteur
% près. Surtout l'espèce de plateau entre 25 et 30min. J'ai essayé de les
% regrouper pour voir. Au final c'est pas exactement pareil mais ça reste
% troublant. J'ai aussi marqué les points qui ne sont PAS interpolés. On ne
% peut pas avoir le résultat à 60min avec un timestep^de 25min, ça ne tombe
% pas rond. C'est peut être ça qui fout la merde...

%% Fonctions

    function results = fit_results(LOC, fitType, startPoint)
        if ~exist('startPoint', 'var')
            startPoint = [];
        end
        
        ID = 12:12:72;
        gcf; clf; hold all;
        results = [];
        for i = 1:length(ID)     
            
            if isempty(startPoint)
                [f, gof] = fit(LOC.timesteps',LOC.rmse(:,ID(i))*100, fitType);
            else
                [f, gof] = fit(LOC.timesteps',LOC.rmse(:,ID(i))*100, fitType, ...
                    'StartPoint', startPoint);
            end
            
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
        xlabel('TimeStep [min]')
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