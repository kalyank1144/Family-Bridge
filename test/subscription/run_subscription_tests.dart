#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Test runner script for subscription system tests
/// 
/// This script runs all subscription-related tests and generates a comprehensive report.
/// It can be run from the command line or integrated into CI/CD pipelines.
/// 
/// Usage:
/// dart run test/subscription/run_subscription_tests.dart [options]
/// 
/// Options:
/// --coverage: Generate coverage report
/// --integration: Run integration tests only
/// --unit: Run unit tests only
/// --verbose: Verbose output
/// --report: Generate HTML report
void main(List<String> args) async {
  final config = TestRunnerConfig.fromArgs(args);
  final runner = SubscriptionTestRunner(config);
  
  print('🧪 Running Family Bridge Subscription Tests');
  print('=' * 50);
  
  try {
    final results = await runner.run();
    await runner.generateReport(results);
    
    print('\n✅ Test run completed successfully!');
    print('Results: ${results.passed}/${results.total} tests passed');
    
    if (results.failed > 0) {
      print('❌ ${results.failed} tests failed');
      exit(1);
    }
  } catch (error) {
    print('\n❌ Test run failed: $error');
    exit(1);
  }
}

class TestRunnerConfig {
  final bool generateCoverage;
  final bool integrationOnly;
  final bool unitOnly;
  final bool verbose;
  final bool generateReport;

  const TestRunnerConfig({
    this.generateCoverage = false,
    this.integrationOnly = false,
    this.unitOnly = false,
    this.verbose = false,
    this.generateReport = false,
  });

  factory TestRunnerConfig.fromArgs(List<String> args) {
    return TestRunnerConfig(
      generateCoverage: args.contains('--coverage'),
      integrationOnly: args.contains('--integration'),
      unitOnly: args.contains('--unit'),
      verbose: args.contains('--verbose'),
      generateReport: args.contains('--report'),
    );
  }
}

class SubscriptionTestRunner {
  final TestRunnerConfig config;
  
  const SubscriptionTestRunner(this.config);

  Future<TestResults> run() async {
    final results = TestResults();
    
    if (!config.integrationOnly) {
      print('\n📝 Running unit tests...');
      final unitResults = await _runUnitTests();
      results.merge(unitResults);
    }
    
    if (!config.unitOnly) {
      print('\n🔗 Running integration tests...');
      final integrationResults = await _runIntegrationTests();
      results.merge(integrationResults);
    }
    
    if (config.generateCoverage) {
      print('\n📊 Generating coverage report...');
      await _generateCoverageReport();
    }
    
    return results;
  }

  Future<TestResults> _runUnitTests() async {
    final testFiles = [
      'test/subscription/services/subscription_backend_service_test.dart',
      'test/subscription/services/payment_service_test.dart',
      'test/subscription/services/offline_payment_service_test.dart',
      'test/subscription/providers/subscription_provider_test.dart',
    ];
    
    return await _runTestFiles(testFiles, 'Unit Tests');
  }

  Future<TestResults> _runIntegrationTests() async {
    final testFiles = [
      'test/subscription/integration/payment_flow_integration_test.dart',
    ];
    
    return await _runTestFiles(testFiles, 'Integration Tests');
  }

  Future<TestResults> _runTestFiles(List<String> testFiles, String category) async {
    final results = TestResults();
    
    print('  Running $category:');
    
    for (final testFile in testFiles) {
      final fileName = testFile.split('/').last;
      print('    • $fileName');
      
      final result = await _runSingleTest(testFile);
      results.merge(result);
      
      if (config.verbose) {
        print('      ✅ ${result.passed} passed, ❌ ${result.failed} failed');
      }
    }
    
    print('  $category Results: ${results.passed}/${results.total} tests passed');
    return results;
  }

  Future<TestResults> _runSingleTest(String testFile) async {
    try {
      final process = await Process.run(
        'flutter',
        ['test', testFile, '--reporter', 'json'],
        workingDirectory: '.',
      );
      
      if (process.exitCode != 0) {
        if (config.verbose) {
          print('    ❌ Test failed with exit code ${process.exitCode}');
          print('    stderr: ${process.stderr}');
        }
        return TestResults(failed: 1, total: 1);
      }
      
      // Parse JSON output to get detailed results
      final output = process.stdout as String;
      return _parseTestOutput(output);
      
    } catch (error) {
      if (config.verbose) {
        print('    ❌ Error running test: $error');
      }
      return TestResults(failed: 1, total: 1);
    }
  }

  TestResults _parseTestOutput(String jsonOutput) {
    final results = TestResults();
    
    try {
      final lines = jsonOutput.split('\n').where((line) => line.trim().isNotEmpty);
      
      for (final line in lines) {
        final json = jsonDecode(line);
        
        if (json['type'] == 'testDone') {
          results.total++;
          
          if (json['result'] == 'success') {
            results.passed++;
          } else {
            results.failed++;
            results.failures.add(TestFailure(
              testName: json['testName'] ?? 'Unknown test',
              error: json['error'] ?? 'Unknown error',
              stackTrace: json['stackTrace'] ?? '',
            ));
          }
        }
      }
    } catch (error) {
      // Fallback: assume single test passed if no JSON parsing errors
      if (jsonOutput.contains('All tests passed')) {
        results.total++;
        results.passed++;
      } else {
        results.total++;
        results.failed++;
      }
    }
    
    return results;
  }

  Future<void> _generateCoverageReport() async {
    try {
      // Run tests with coverage
      await Process.run(
        'flutter',
        ['test', '--coverage', 'test/subscription/'],
        workingDirectory: '.',
      );
      
      // Generate LCOV report
      await Process.run(
        'genhtml',
        ['coverage/lcov.info', '-o', 'coverage/html'],
        workingDirectory: '.',
      );
      
      print('  📊 Coverage report generated in coverage/html/');
    } catch (error) {
      print('  ⚠️  Could not generate coverage report: $error');
    }
  }

  Future<void> generateReport(TestResults results) async {
    if (!config.generateReport) return;
    
    final report = _generateHtmlReport(results);
    final reportFile = File('test_reports/subscription_tests.html');
    
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(report);
    
    print('\n📄 HTML report generated: ${reportFile.path}');
  }

  String _generateHtmlReport(TestResults results) {
    final now = DateTime.now();
    final passRate = results.total > 0 ? (results.passed / results.total * 100).toStringAsFixed(1) : '0.0';
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <title>Subscription Tests Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f5f5f5; padding: 20px; border-radius: 5px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .stat { background: white; padding: 15px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat.passed { border-left: 4px solid #4caf50; }
        .stat.failed { border-left: 4px solid #f44336; }
        .stat.total { border-left: 4px solid #2196f3; }
        .failures { margin-top: 20px; }
        .failure { background: #ffebee; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .failure-name { font-weight: bold; color: #d32f2f; }
        .failure-error { margin: 10px 0; font-family: monospace; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧪 Subscription System Test Report</h1>
        <div class="timestamp">Generated: ${now.toString()}</div>
    </div>
    
    <div class="summary">
        <div class="stat total">
            <h3>Total Tests</h3>
            <div style="font-size: 2em; font-weight: bold;">${results.total}</div>
        </div>
        <div class="stat passed">
            <h3>Passed</h3>
            <div style="font-size: 2em; font-weight: bold; color: #4caf50;">${results.passed}</div>
        </div>
        <div class="stat failed">
            <h3>Failed</h3>
            <div style="font-size: 2em; font-weight: bold; color: #f44336;">${results.failed}</div>
        </div>
        <div class="stat">
            <h3>Pass Rate</h3>
            <div style="font-size: 2em; font-weight: bold; color: ${results.failed == 0 ? '#4caf50' : '#ff9800'};">$passRate%</div>
        </div>
    </div>
    
    ${results.failures.isNotEmpty ? '''
    <div class="failures">
        <h2>❌ Test Failures</h2>
        ${results.failures.map((failure) => '''
        <div class="failure">
            <div class="failure-name">${failure.testName}</div>
            <div class="failure-error">${failure.error}</div>
            ${failure.stackTrace.isNotEmpty ? '<pre>${failure.stackTrace}</pre>' : ''}
        </div>
        ''').join('')}
    </div>
    ''' : '<div style="color: #4caf50; font-size: 1.2em; margin-top: 20px;">🎉 All tests passed!</div>'}
    
    <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 0.9em;">
        <p>Test Categories Covered:</p>
        <ul>
            <li>✅ Subscription Backend Service</li>
            <li>✅ Payment Processing Service</li>
            <li>✅ Offline Payment Queue</li>
            <li>✅ Subscription Provider (State Management)</li>
            <li>✅ Payment Flow Integration</li>
            <li>✅ Feature Access Control</li>
            <li>✅ Error Handling & Recovery</li>
        </ul>
    </div>
</body>
</html>
''';
  }
}

class TestResults {
  int passed = 0;
  int failed = 0;
  int total = 0;
  List<TestFailure> failures = [];

  TestResults({this.passed = 0, this.failed = 0, this.total = 0});

  void merge(TestResults other) {
    passed += other.passed;
    failed += other.failed;
    total += other.total;
    failures.addAll(other.failures);
  }
}

class TestFailure {
  final String testName;
  final String error;
  final String stackTrace;

  const TestFailure({
    required this.testName,
    required this.error,
    required this.stackTrace,
  });
}