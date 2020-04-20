%% Erreur Vs. TimeStep
%
%
%%%
function pbl06_Erreur_VS_TimeStep()
addpath(fullfile(userpath, 'PartageDeCode', 'toolbox'))
addpath(fullfile(userpath, 'PartageDeCode', 'toolbox', 'sources', 'prevision'))
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
% *Ca ne vous para�t pas bizarre que pour Ajaccio et Odeillo, ce sont
% _EXACTEMENT_ les m�mes lignes juste en d�call� ?*
% Voir <#6 plus bas> pour comparaison
%
% Au final ce n'est pas vraiment lin�aire. Plus sur Ajaccio que Odeillo. Le
% plus rentable reste � horizon 60min o� on gagne 1.2% (1.8 pour Odeillo) �
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
% Avec un poly du 2eme degr� on a un meilleur R2, toujours au dessus de
% 0.96. Par contre 'physiquement' je ne sais pas si �a a un sens ...
% En fait on trace le compromis entre la r�solution (TimeStep) et la
% pr�cision (nRMSE). Ca ressemble � un Front de Pareto d'o� l'id�e de
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
% Bon ce n'�tait pas une bonne id�e... on perd en R2. On aurait pu dire,
% avec $\varepsilon$ l'erreur et $dt$ le timestep :
% 
% $$\varepsilon = \frac{p_1}{dt + q_1}$$
%
% $$\varepsilon . (dt + q_1) = cste$$
% 
% En plus les bornes des coefficients trouv�s sont �normes donc assez peu
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
% Les courbes sur Ajaccio et Odeillo avaient l'air identiques � un facteur
% pr�s. Surtout l'esp�ce de plateau entre 25 et 30min. J'ai essay� de les
% regrouper pour voir. Au final c'est pas exactement pareil mais �a reste
% troublant. J'ai aussi marqu� les points qui ne sont PAS interpol�s. On ne
% peut pas avoir le r�sultat � 60min avec un timestep^de 25min, �a ne tombe
% pas rond. C'est peut �tre �a qui fout la merde...

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