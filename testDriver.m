% Script to drive running of gQSPSim tests.
addpath(genpath(pwd));
result = runtests("tests");

if batchStartupOptionUsed
    if result.Failed
        exit(3)
    end
end
