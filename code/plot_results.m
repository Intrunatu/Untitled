function plot_results(resultsCell)
%PLOT_RESULTS Summary of this function goes here
%   Detailed explanation goes here
col = lines;
for j =1:length(resultsCell)
    results = resultsCell{j};
    
    figure(2)    
    for i=1:length(results)
        r= results{i};
        dt = r(:,1);
        t = r(:,2);
        rmse = r(:,3);
        plot3(t, dt, rmse, '.-', 'Color', col(j,:)), hold all
    end
    zlabel('nRMSE')
    xlabel('Horizon')
    xticks(0:60:max(xlim))
    ylabel('TimeStep')
    grid on
    zlim([0 0.3])
end

end

