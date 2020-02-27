% Script to drive running of gQSPSim tests.
gQSPSim_Root = string(getenv('HOME')) + "/projects/gQSPSim";
addpath(genpath(gQSPSim_Root));
runtests(gQSPSim_Root + "/tests");
