function [fmList] = train_models(filledTableTrain, modelType, modelTemplate)
%TRAIN_MODELS Summary of this function goes here
%   Detailed explanation goes here
opts.solisOpts=modelTemplate.solisOpts;
for i = 1:12
    dt = 5*i;
    disp([dt 6*60/dt])
    
    opts.timeStep = dt;
    opts.sunHeightLim = modelTemplate.sunHeightLim;
    
    opts.Nhist = ceil(6*60/dt);
    opts.Npred = ceil(6*60/dt);
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

