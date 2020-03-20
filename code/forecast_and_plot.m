clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])


filelist =ls('fmARMA*.mat');
for i=1:size(filelist,1)
    fmList(i) = forecastModel(filelist(i,:));
end

%% Metrics inside
figure(1)
for i =1:length(fmList)
    disp(i)
    fm = fmList(i);
    t = (1:fm.Npred)*fm.timeStep;
    dt = fm.timeStep*ones(1, fm.Npred);
    
    metrics_inside = fm.metrics;  
    plot3(t, dt, metrics_inside{6,2:end}), hold all
end

%%

rawData = load([userpath '\Data\Donn�es odeillo\Odeillo_UTC.mat']);
inputTable = timetable(rawData.table.TimeUTC, rawData.table.GHI);
inputTable.Properties.VariableNames={'Irradiance'};
inputTable(isnat(inputTable.Time),:)=[];
inputTable(inputTable.Irradiance<0,:) = [];
inputTableForecast=inputTable(5638657:end,:); % Du 01/01/15 au 18/10/16
clearvars rawData



results = cell(size(fmList));
for i =1:length(fmList)
    disp(i)
    fm = fmList(i);
    t = (1:fm.Npred)*fm.timeStep;
    dt = fm.timeStep*ones(1, fm.Npred);
   
    % Calcul complet pour faire les erreurs � la main. Long � cause du fillGaps
    [timePred, GiPred, GiMeas, isFilled, avgTable] = fm.forecast_full(inputTableForecast);
    GiMeas(isFilled) = NaN;
    GiPred(isFilled) = NaN;
    metrics = fm.get_metrics(GiMeas, GiPred);   
    results{i} = [dt', t',   metrics{6,2:end}'];
end


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



figure(3)
x = results{1}(:,2);
y = results{1}(1,1);
z = results{1}(:,3);


for i=2:length(results)
    r= results{i};
    dt = r(:,1);
    t = r(:,2);
    y = [y results{i}(1,1)];
    rmse = r(:,3);
    
    z = [z interp1(t,rmse,x)];
end

surf(x,y,z')
zlabel('nRMSE')
xlabel('Horizon')
xticks(0:60:max(xlim))
ylabel('TimeStep')
grid on