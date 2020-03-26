clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
load('filledTables')


%% Entraine les modèles
% fmList = train_models(filledTableTrain, 'ARMA', fm1);
% save(sprintf("fmArray_%s_6h", fmList(1).modelType), 'fmList')
load('fmArray_ARMA_6h.mat')

% Metrics inside
figure(1)
for i =1:length(fmList)
    fm = fmList(i);
    t = (1:fm.Npred)*fm.timeStep;
    dt = fm.timeStep*ones(1, fm.Npred);
    
    metrics_inside = fm.metrics;  
    plot3(t, dt, metrics_inside{6,2:end}), hold all
end

%% Metrics outide
% results = calc_results(fmList,filledTableForecast);
% save(sprintf("results_%s_6h", fmList(1).modelType), 'results')
load('results_NN_6h.mat')

%% Affichages

figure(2), clf
for i = 1:length(results)
    r  = results{i};
    dt = r(:,1);
    t  = r(:,2);
    rmse = r(:,3);
    plot3(t, dt, rmse, '.-'), hold all
end
zlabel('nRMSE')
xlabel('Horizon')
xticks(0:60:max(xlim))
ylabel('TimeStep')
grid on



figure(3), clf
x = results{1}(:,2);
y = results{1}(1,1);
z = results{1}(:,3)';
for i=2:length(results)
    r= results{i};
    dt = r(:,1);
    t = r(:,2);
    y = [y results{i}(1,1)];
    rmse = r(:,3);
    
    z = [z; interp1(t,rmse,x)'];    
end
[minRMSE, id]=min(z); % valeurs min du nRMSE pour chaque horizon (Cyril)
surf(x,y,z)
hold all
scatter3(x, y(id),minRMSE, 'r', 'filled')
zlabel('nRMSE')
xlabel('Horizon')
xticks(0:60:max(xlim))
ylabel('TimeStep')
grid on
zlim([0 0.3])


figure(4)
plot(x, y(id))
xlabel('Horizon')
xticks(0:60:max(xlim))
ylabel('TimeStep')

