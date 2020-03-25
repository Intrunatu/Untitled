function [results] = calc_results(fmList,filledTableForecast)
%CALC_RESULTS Summary of this function goes here
%   Detailed explanation goes here
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
end

