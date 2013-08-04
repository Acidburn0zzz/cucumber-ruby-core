# encoding: UTF-8¬
require 'cucumber/initializer'

module Cucumber
  module Core
    module Test
      module Result
        def self.status_queries(status)
          Module.new do
            [:passed, :failed, :undefined, :unknown, :skipped].each do |possible_status|
              define_method("#{possible_status}?") do
                possible_status == status
              end
            end
          end
        end

        Unknown = Class.new do
          include Result.status_queries :unknown

          def describe_to(visitor, *args)
            self
          end
        end

        class Passed
          include Result.status_queries :passed
          include Cucumber.initializer(:duration)
          attr_reader :duration

          def initialize(duration)
            raise ArgumentError unless duration
            super
          end

          def describe_to(visitor, *args)
            visitor.passed(*args)
            visitor.duration(duration, *args)
            self
          end

          def to_s
            "✓"
          end
        end

        class Failed
          include Result.status_queries :failed
          include Cucumber.initializer(:duration, :exception)
          attr_reader :duration, :exception

          def initialize(duration, exception)
            raise ArgumentError unless duration 
            raise ArgumentError unless exception
            super
          end

          def describe_to(visitor, *args)
            visitor.failed(*args)
            visitor.duration(duration, *args)
            visitor.exception(exception, *args) if exception
            self
          end

          def to_s
            "✗"
          end

        end

        Undefined = Struct.new(:exception) do
          include Result.status_queries :undefined

          def describe_to(visitor, *args)
            visitor.undefined(*args)
            self
          end

          def to_s
            "✗"
          end
        end

        Skipped = Class.new do
          include Result.status_queries :skipped

          def describe_to(visitor, *args)
            visitor.skipped(*args)
            self
          end

          def to_s
            "-"
          end
        end

        class Summary
          attr_reader :total_failed,
            :total_passed,
            :total_skipped,
            :total_undefined,
            :exceptions,
            :durations

          def initialize
            @total_failed =
              @total_passed =
              @total_skipped =
              @total_undefined = 0
            @exceptions = []
            @durations = []
          end

          def failed(*args)
            @total_failed += 1
            self
          end

          def passed(*args)
            @total_passed += 1
            self
          end

          def skipped(*args)
            @total_skipped +=1
            self
          end

          def undefined(*args)
            @total_undefined += 1
            self
          end

          def exception(exception)
            @exceptions << exception
            self
          end

          def duration(duration)
            @durations << duration
            self
          end

          def total
            total_passed + total_failed + total_skipped + total_undefined
          end
        end
      end
    end
  end
end
