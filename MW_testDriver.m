import matlab.unittest.TestRunner
import matlab.unittest.Verbosity
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat
import matlab.unittest.plugins.XMLPlugin

pwd

DefinePaths(true);

% Some testing infrasctructure is not available on all version of MATLAB we are testing.
testTags = {'RequiresUserInterface'};
if ~verLessThan('matlab', '9.10.0')
    testTags{end+1} = 'RequiresModernTestInfrastructure';
end

suite = testsuite('tests', 'Tag', testTags);

[~, ~] = mkdir('artifacts');

runner = TestRunner.withTextOutput('OutputDetail', Verbosity.Detailed);
runner.addPlugin(CodeCoveragePlugin.forFolder('tests', 'Producing', CoberturaFormat('artifacts/coverage.xml')));
runner.addPlugin(XMLPlugin.producingJUnitFormat('artifacts/testResults.xml'));

results = runner.run(suite);

assertSuccess(results);
