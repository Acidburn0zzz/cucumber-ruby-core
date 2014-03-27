module Cucumber
  module Core
    class Decompiler
      include Cucumber.initializer(:receiver)

      def before_test_case(test_case, &continue)
        test_case.describe_source_to repetition_filter, on_after_step
        continue.call
      end

      def after_test_case(test_case, result)
      end

      def before_test_step(test_step)
        test_step.describe_source_to repetition_filter, on_after_step
      end

      def after_test_step(test_step, result)
        @last_step_result = result
      end

      def done
      end

      private

      def on_after_step
        -> (block) { block.call @last_step_result }
      end

      def repetition_filter
        @repetition_filter ||= RepetitionFilter.new(receiver)
      end

      class RepetitionFilter
        include Cucumber.initializer(:receiver)

        def feature(node, after_step)
          return if node == @feature
          receiver.feature(node)
          @feature = node
        end

        def scenario(node, after_step)
          return if node == @scenario
          receiver.scenario(node)
          @scenario = node
        end

        def step(node, after_step)
          return if node == @step
          receiver.step(node, after_step)
          @step = node
        end
      end

    end

  end
end
