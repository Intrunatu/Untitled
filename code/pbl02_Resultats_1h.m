clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])
load('filledTables')


timeSteps = [ 5 10 15 30];
% modelList = {'ARMA', 'NN', 'RF', 'SVR', 'GP'};
modelList = {'ARMA', 'NN', 'SVR'};


for i = 1:length(modelList)
    tic
    fmList(i,:) = train_models(filledTableTrain, modelList{i}, fm1, timeSteps, 60);
    toc
end

%%

metrics = cell(size(fmList));
for i =1:numel(fmList)
    disp(i)
    fm = fmList(i);
    % Calcul complet pour faire les erreurs à la main. Long à cause du fillGaps
    [timePred, GiPred, GiMeas, isFilled, avgTable] = fm.forecast_full(filledTableForecast);
    GiMeas(isFilled) = NaN;
    GiPred(isFilled) = NaN;
    metrics{i} = fm.get_metrics(GiMeas, GiPred);   
end


%%
figure(2), clf
col = lines;
for iTS = 1:size(fmList,2)
    for iModel = 1:size(fmList,1)
        fm = fmList(iModel,iTS);
        steps = fm.timeStep*(1:fm.Npred);
        plot3(steps,...
            repmat(timeSteps(iTS),length(steps),1),...
            fm.metrics{6,2:end}*100, '.-', ...
            'DisplayName', modelList{iModel},...
            'Color', col(iModel,:))
        hold all
    end
    grid on
    xlabel('Horizon [min]')
    ylabel('TimeStep [min]')
    zlabel('nRMSE [%]')
%     ylim([6 20])
end