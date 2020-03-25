clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
load('filledTables')


%% Entraine les modèles
opts.solisOpts=fm1.solisOpts;
for i = 1:12
    dt = 5*i;
    disp([dt 6*60/dt])
    
    opts.timeStep = dt;
    opts.sunHeightLim = fm1.sunHeightLim;
    
    opts.Nhist = ceil(6*60/dt);
    opts.Npred = ceil(6*60/dt);
    opts.Nskip = 0;
    
    tic
    rng(1)
    fmList(i) = forecastModel(filledTableTrain, 'ARMA', opts,...
        'plot'                  , false                             , ...
        'fillGaps'              , false                             , ...
        'gapInterpolationLimit' , fm1.cleanPara.interpolation_limit , ...
        'gapPersistenceLimit'   , fm1.cleanPara.persistence_limit   , ...
        'gapClearskyLimit'      , fm1.cleanPara.clearsky_limit      , ...
        'nightBehaviour'        , fm1.nightBehaviour                , ...
        'verbose'               , false);
    toc
end
save("fmArray_ARMA_6h", 'fmList')

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
    fm.cleanPara.enable = false;
   
    % Calcul complet pour faire les erreurs à la main. Long à cause du fillGaps
    [timePred, GiPred, GiMeas, isFilled, avgTable] = fm.forecast_full(filledTableForecast);
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
