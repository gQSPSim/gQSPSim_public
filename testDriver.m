% Script to drive running of gQSPSim tests on gitlab-runner.
addpath(genpath(pwd));
result = runtests("tests");

if result.Failed
    exit(3);
else
    exit(0);
end
