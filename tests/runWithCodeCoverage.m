import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.CodeCoveragePlugin

suite = TestSuite.fromFile('tests/tgQSPSim.m');

runner = TestRunner.withTextOutput;

runner.addPlugin(CodeCoveragePlugin.forFolder('.', 'IncludingSubfolders', true));
result = runner.run(suite);
