require 'cucumber/core/gherkin/parser'
require 'cucumber/core/compiler'
require 'cucumber/core/test/runner'
require 'cucumber/core/test/mapper'
require 'cucumber/core/test/hook_compiler'

module Cucumber
  module Core

    def parse(gherkin_documents, compiler)
      parser = Core::Gherkin::Parser.new(compiler)
      parser.test_suite(gherkin_documents)
      self
    end

    def compile(gherkin_documents, last_receiver, filters = [])
      first_receiver = filters.reduce(last_receiver) do |receiver, (filter_type, args)|
        filter_type.new(*args + [receiver])
      end
      compiler = Compiler.new(first_receiver)
      parse gherkin_documents, compiler
      self
    end

    def execute(gherkin_documents, mappings, report, filters = [])
      receiver = Test::Runner.new(report)
      filters << [Test::HookCompiler, [mappings]]
      filters << [Test::Mapper, [mappings]]
      compile gherkin_documents, receiver, filters
      self
    end

  end
end
