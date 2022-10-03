% Script to drive running of gQSPSim tests on gitlab-runner.
genericError = '';

% Add gQSPSim to the path.
DefinePaths;

% Add test directory to the path.
addpath(genpath('tests'));

try
    %results = runtests('tgQSPSim', 'ProcedureName', 'tSimulations');
    %results = runtests('tTMDD');
    results = runtests('tsimple', 'strict', false);
catch e
    results.Failed = true;
    genericError = e.message;
end

if any([results.Failed])
    warning('Some errors encountered. See log file for details.');
    if ~isempty(genericError)
        warning(genericError);
    end
    exit(1)
else
    exit
end
