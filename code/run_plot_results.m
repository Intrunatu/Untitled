clear all; close all; clc
addpath([userpath '\PartageDeCode\toolbox\'])
addpath([userpath '\PartageDeCode\toolbox\sources\prevision\'])

rARMA = load('results_ARMA_6h.mat');
rNN = load('results_NN_6h.mat');

allResults{1} = rARMA.results;
allResults{2} = rNN.results;

plot_results(allResults)