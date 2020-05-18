% Script to drive running of gQSPSim tests on gitlab-runner.
addpath(genpath(pwd));
results = runtests("tests");

if any([tests.Failed])
    error('Some errors encountered. See log file for details.');
end

