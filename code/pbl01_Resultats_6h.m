%% Resultats
%
% L'objectif est de tracer la nRMSE en fonction de l'horizon et du pas de
% temps du modèle. Comme les données sont moyénées avec ce pas de temps,
% l'interêt est de voir si cela fait baisser l'erreur. J'aimerais mettre en
% valeur le compromis entre le pas de temps faible (bonne fréquence de
% pred) et la nRMSE (bonne qualité).
%
% Options des modèles : 
% 
% * 6h historique
% * 6h predictions
% * pas de saut avant 1ere mesure
% * Lignes contenant une nuit ($h>5^\circ$) supprimées
%
% 

%% Préparation des données
% Pour éviter de refaire le fillgaps à chaque fois, on le fait une 1ere
% fois et on sauvegarde les tables pour l'apprentissage, les tests et le
% modèle qui a servi à parametrer fillgaps. On entraine ensuite les modèles
% avec horizon max 6h et des timesteps allant de 5 min à 1h. Les modèles
% sont sauvegardés pour pouvoir être réutilisés. On calcule ensuite les
% erreurs sur la table de test et on les sauvegarde

if false
    prepare_tables
    
    load('filledTables')    
    fmList = train_models(filledTableTrain, 'ARMA', fm1, 5:5:60, 6*60);
    save(sprintf("fmArray_%s_6h", fmList(1).modelType), 'fmList')
    
    results = calc_results(fmList,filledTableForecast);
    save(sprintf("results_%s_6h", fmList(1).modelType), 'results')
end

%% Résultats Odeillo - ARMA
% Les résultas ont l'air corrects. Sur les petits pas de temps, on a une
% erreur élevée, sans doute due aux pics qui ne sont pas lissés avec le
% moyennage 5 minutes. Les meilleurs résultats sont pour des pas de temps
% entre 25 et 50 min. On note une augmentation après 50min, pourquoi ??

load('results_ARMA_6h.mat')

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
grid on

% Interpolation pour affichage en surface
figure(2), clf
T = results{1}(:,2);    % Horizon de pred
dt = results{1}(1,1);   % Timestep
err = results{1}(:,3)'; % Erreur
for i=2:length(results)
    r= results{i};
    t = r(:,2);                 % Horizon de pred
    dt = [dt results{i}(1,1)];  % Concatene timestep
    rmse = r(:,3);              % Erreur
    
    % Interpole sur les horizons du modele 5min
    err = [err; interp1(t,rmse,T)'];
end
surf(T,dt,err)
hold all
zlabel('nRMSE')
xlabel('Horizon')
xticks(0:60:max(xlim))
ylabel('TimeStep')
grid on

% Valeurs min du nRMSE pour chaque horizon (Cyril)
[minRMSE, id]=min(err); 
scatter3(T, dt(id),minRMSE, 'r', 'filled')


%% 
% Si on essaye de récupérer le timestep qui produit la plus petite RMSE
% pour chaque horizon (en rouge sur la surface), on obtient cette figure.
% Cela va être difficile de généraliser quelque chose...
clf
plot(T, dt(id))
xlabel('Horizon')
xticks(0:60:max(xlim))
ylabel('TimeStep')
grid on


%% Résultats Odeillo - NN
% Pour le NN c'est plus compliqué. Déjà on voit qu'il supporte beaucoup
% moins bien les petits pas de temps ! On dépasse même les 100% de nRMSE.
% En zoomant sur l'axe Z pour avoir la même plage qu'ARMA, les résultats
% sont aussi beaucoup plus bruités. Je n'essaye même pas le coup du
% timestep optim par horizon. 
% 
% Est ce que le bruit est du à la non linéarité des NN ? Un modèle linéaire
% comme ARMA lisse la réponse, pas les NN. Surtout pour les pas de temps
% faibles. On n'aurait pas un problème de sur entrainement ?

load('results_NN_6h.mat')

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
grid on
snapnow;
zlim([0,0.3])


% Interpolation pour affichage en surface
figure(2), clf
T = results{1}(:,2);    % Horizon de pred
dt = results{1}(1,1);   % Timestep
err = results{1}(:,3)'; % Erreur
for i=2:length(results)
    r= results{i};
    t = r(:,2);                 % Horizon de pred
    dt = [dt results{i}(1,1)];  % Concatene timestep
    rmse = r(:,3);              % Erreur
    
    % Interpole sur les horizons du modele 5min
    err = [err; interp1(t,rmse,T)'];
end
err(err>0.3) = NaN;
surf(T,dt,err)
hold all
zlabel('nRMSE')
xlabel('Horizon')
xticks(0:60:max(xlim))
ylabel('TimeStep')
grid on
zlim([0,0.3])

% Valeurs min du nRMSE pour chaque horizon (Cyril)
[minRMSE, id]=min(err); 
scatter3(T, dt(id),minRMSE, 'r', 'filled')

%% Comparaison Odeillo
% En comparant les deux résultats, on voit que le ARMA est toujours
% meilleur que le NN... A confirmer !

rARMA = load('results_ARMA_6h.mat');
rNN = load('results_NN_6h.mat');

resultsCell{1} = rARMA.results;
resultsCell{2} = rNN.results;

col = lines;
figure(1), clf
for j =1:length(resultsCell)
    results = resultsCell{j};
    for i = 1:length(results)
        r  = results{i};    % Matrice des resultats
        dt = r(:,1);        % Timestep
        t  = r(:,2);        % Horizon de pred
        rmse = r(:,3);      % Erreur
        plot3(t, dt, rmse, '.-', 'Color', col(j,:)), hold all
    end
    zlabel('nRMSE')
    xlabel('Horizon')
    xticks(0:60:max(xlim))
    ylabel('TimeStep')
    grid on
    zlim([0 0.3])    
end