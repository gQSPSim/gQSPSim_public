import matlab.unittest.TestRunner
import matlab.unittest.Verbosity
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat
import matlab.unittest.plugins.XMLPlugin

pwd

DefinePaths(true);

suite = testsuite('tests', 'Tag', 'RequiresUserInterface');

[~, ~] = mkdir('artifacts');

runner = TestRunner.withTextOutput('OutputDetail', Verbosity.Detailed);
runner.addPlugin(CodeCoveragePlugin.forFolder('tests', 'Producing', CoberturaFormat('artifacts/coverage.xml')));
runner.addPlugin(XMLPlugin.producingJUnitFormat('artifacts/testResults.xml'));

results = runner.run(suite);

assertSuccess(results);
