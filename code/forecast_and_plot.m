clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
load('inputTableForecast')

data = load("fmArray_ARMA_6h.mat", 'fm');
fmList = data.fm;

%% Metrics inside
figure(1)
for i =1:length(fmList)
    fm = fmList(i);
    t = (1:fm.Npred)*fm.timeStep;
    dt = fm.timeStep*ones(1, fm.Npred);
    
    metrics_inside = fm.metrics;  
    plot3(t, dt, metrics_inside{6,2:end}), hold all
end

%% Metrics outide

results = cell(size(fmList));
for i =1:length(fmList)
    disp(i)
    fm = fmList(i);
    t = (1:fm.Npred)*fm.timeStep;
    dt = fm.timeStep*ones(1, fm.Npred);
   
    % Calcul complet pour faire les erreurs à la main. Long à cause du fillGaps
    [timePred, GiPred, GiMeas, isFilled, avgTable] = fm.forecast_full(inputTableForecast);
    GiMeas(isFilled) = NaN;
    GiPred(isFilled) = NaN;
    metrics = fm.get_metrics(GiMeas, GiPred);   
    results{i} = [dt', t',   metrics{6,2:end}'];
end

%%
figure(2), clf
for i=1:length(results)
    r= results{i};
    dt = r(:,1);
    t = r(:,2);
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

figure(4)
plot(x, y(id))
xlabel('Horizon')
xticks(0:60:max(xlim))
ylabel('TimeStep')
