require 'cucumber/core'
require 'cucumber/core/gherkin/writer'
require 'cucumber/core/platform'

module Cucumber
  describe Core do
    include Core
    include Core::Gherkin::Writer

    describe "parsing Gherkin" do
      it "calls the compiler with a valid AST" do
        compiler = double
        compiler.should_receive(:feature) do |feature|
          feature.should respond_to(:describe_to)
        end

        gherkin = gherkin do
          feature do
            scenario do
              step
            end
          end
        end

        parse([gherkin], compiler)
      end
    end

    describe "compiling features to a test suite" do
      it "compiles two scenarios into two test cases" do
        visitor = double
        visitor.should_receive(:test_case).exactly(2).times.and_yield.ordered
        visitor.should_receive(:test_step).exactly(5).times.ordered

        compile([
          gherkin do
            feature do
              background do
                step
              end
              scenario do
                step
              end
              scenario do
                step
                step
              end
            end
          end
        ], visitor)
      end

    end

    describe "mapping test cases" do
      it "foo" do
        gherkin = gherkin do
          feature do
            scenario do
              step
            end
          end
        end
        runner = double('runner')
        mappings = double('mappings')
        runner.should_receive(:test_case)
        runner.should_receive(:mapped_step).once
        map([gherkin], mappings, runner)
      end

    end

    describe "executing test_cases" do
      class ReportSpy
        attr_reader :test_cases, :test_steps

        def initialize
          @test_cases = Core::Test::Result::Summary.new
          @test_steps = Core::Test::Result::Summary.new
        end

        def after_test_case(test_case, result)
          result.describe_to test_cases
        end

        def after_test_step(test_step, result)
          result.describe_to test_steps
        end

        def method_missing(*)
        end
      end

      class FakeMappings
        Failure = Class.new(StandardError)

        def execute(step)
          raise Failure if step.name =~ /fail/
        end
      end

      it "executes the test cases in the suite" do
        gherkin = gherkin do
            feature 'Feature name' do
              scenario 'The one that passes' do
                step 'passing'
              end

              scenario 'The one that fails' do
                step 'passing'
                step 'failing'
              end
            end
          end
        report = ReportSpy.new
        mappings = FakeMappings.new

        execute [gherkin], mappings, report

        report.test_cases.total.should eq(2)
        report.test_cases.total_passed.should eq(1)
        report.test_cases.total_failed.should eq(1)
        report.test_steps.total.should eq(3)
        report.test_steps.total_passed.should eq(2)
        report.test_steps.total_failed.should eq(1)
      end
    end
  end
end
