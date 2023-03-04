import matlab.unittest.TestRunner
import matlab.unittest.Verbosity
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat
import matlab.unittest.plugins.XMLPlugin

DefinePaths(true);

suite = testsuite('tests', 'Tag', 'NoUI');

[~, ~] = mkdir('artifacts');

% Number of warnings that are allowed by the test cases provided by Genentech.
% These must be suppressed in order to keep logs at a reasonable size.
warning('off', 'SimBiology:REACTIONRATE_INVALID');

runner = TestRunner.withTextOutput('OutputDetail', Verbosity.Detailed);
runner.addPlugin(CodeCoveragePlugin.forFolder('tests', 'Producing', CoberturaFormat('artifacts/coverage.xml')));
runner.addPlugin(XMLPlugin.producingJUnitFormat('artifacts/testResults.xml'));

results = runner.run(suite);

assertSuccess(results);
