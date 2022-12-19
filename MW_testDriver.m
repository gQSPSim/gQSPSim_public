import matlab.unittest.TestRunner
import matlab.unittest.Verbosity
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.selectors.HasTag

DefinePaths(true);

suite = testsuite('tests');
selector = HasTag("RequiresUserInterface");

if ~verLessThan('matlab', '9.10.0')
    selector = selector & HasTag("RequiresModernTestInfrastructure");    
else
    selector = selector & ~HasTag("RequiresModernTestInfrastructure");    
end

% For now run the CLI tests at MW for debugging, remove when done.
selector = selector | HasTag("NoUI");

suite = suite.selectIf(selector);

[~, ~] = mkdir('artifacts');

runner = TestRunner.withTextOutput('OutputDetail', Verbosity.Detailed);
runner.addPlugin(CodeCoveragePlugin.forFolder('tests', 'Producing', CoberturaFormat('artifacts/coverage.xml')));
runner.addPlugin(XMLPlugin.producingJUnitFormat('artifacts/testResults.xml'));

results = runner.run(suite);

assertSuccess(results);
