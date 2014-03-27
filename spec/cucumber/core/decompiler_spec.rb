require 'cucumber/core'
require 'cucumber/core/decompiler'
require 'cucumber/core/gherkin/writer'

module Cucumber::Core
  describe Decompiler do
    include Gherkin::Writer
    include Cucumber::Core

    it "compiles a feature with a single scenario" do
      gherkin_documents = [
        gherkin do
          feature 'f' do
            scenario 's' do
              step 'passing'
            end
          end
        end
      ]
      compile_then_decompile(gherkin_documents) do |receiver|
        expect( receiver ).to receive(:feature).once.ordered do |feature|
          feature.name.should == 'f'
        end
        expect( receiver ).to receive(:scenario).once.ordered do |scenario|
          scenario.name.should == 's'
        end
        expect( receiver ).to receive(:step).once.ordered do |step, after_step|
          step.name.should == 'passing'
          on_after_step = -> (result) { result.should be_passing }
          after_step.call(on_after_step)
        end
      end
    end

    def compile_then_decompile(gherkin_documents)
      receiver = double
      yield receiver
      mappings = StepTestMappings.new
      execute gherkin_documents, mappings, Decompiler.new(receiver)
    end

    class StepTestMappings
      Failure = Class.new(StandardError)

      def test_case(test_case, mapper)
        self
      end

      def test_step(step, mapper)
        mapper.map { raise Failure } if step.name =~ /fail/
        mapper.map {}                if step.name =~ /pass/
        self
      end
    end

  end
end


