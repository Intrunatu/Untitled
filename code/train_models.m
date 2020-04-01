function [fmList] = train_models(filledTableTrain, modelType,...
    modelTemplate, timeSteps, maxHorizon)
%TRAIN_MODELS Summary of this function goes here
%   Detailed explanation goes here
opts.solisOpts=modelTemplate.solisOpts;
for i = 1:length(timeSteps)
    dt = timeSteps(i);
    disp([dt maxHorizon/dt])
    
    opts.timeStep = dt;
    opts.sunHeightLim = modelTemplate.sunHeightLim;
    
    opts.Nhist = ceil(maxHorizon/dt);
    opts.Npred = ceil(maxHorizon/dt);
    opts.Nskip = 0;
    
    tic
    rng(1)
    fmList(i) = forecastModel(filledTableTrain, modelType, opts,...
        'plot'                  , false                             , ...
        'fillGaps'              , false                             , ...
        'gapInterpolationLimit' , modelTemplate.cleanPara.interpolation_limit , ...
        'gapPersistenceLimit'   , modelTemplate.cleanPara.persistence_limit   , ...
        'gapClearskyLimit'      , modelTemplate.cleanPara.clearsky_limit      , ...
        'nightBehaviour'        , modelTemplate.nightBehaviour                , ...
        'verbose'               , true);
    toc
end
end

