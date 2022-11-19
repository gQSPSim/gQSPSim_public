import matlab.unittest.TestRunner
import matlab.unittest.Verbosity
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.selectors.HasTag

DefinePaths(true);

suite = testsuite('tests');

if ~verLessThan('matlab', '9.10.0')
    suite = suite.selectIf(HasTag("RequiresUserInterface") & HasTag("RequiresModernTestInfrastructure"));
else
    suite = suite.selectIf(HasTag("RequiresUserInterface") & ~HasTag("RequiresModernTestInfrastructure"));
end

[~, ~] = mkdir('artifacts');

runner = TestRunner.withTextOutput('OutputDetail', Verbosity.Detailed);
runner.addPlugin(CodeCoveragePlugin.forFolder('tests', 'Producing', CoberturaFormat('artifacts/coverage.xml')));
runner.addPlugin(XMLPlugin.producingJUnitFormat('artifacts/testResults.xml'));

results = runner.run(suite);

assertSuccess(results);
