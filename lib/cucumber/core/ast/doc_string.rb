require 'cucumber/core/ast/describes_itself'
module Cucumber
  module Core
    module Ast
      # Represents an inline argument in a step. Example:
      #
      #   Given the message
      #     """
      #     I like
      #     Cucumber sandwich
      #     """
      #
      # The text between the pair of <tt>"""</tt> is stored inside a DocString,
      # which is yielded to the StepDefinition block as the last argument.
      #
      # The StepDefinition can then access the String via the #to_s method. In the
      # example above, that would return: <tt>"I like\nCucumber sandwich"</tt>
      #
      # Note how the indentation from the source is stripped away.
      #
      class DocString
        include DescribesItself
        attr_accessor :file

        def self.default_arg_name
          "string"
        end

        attr_reader :content_type, :content

        def initialize(string, content_type)
          @content = string
          @content_type = content_type
        end

        def map(&block)
          raise ArgumentError unless block
          new_content = block.call(content)
          self.class.new(new_content, content_type)
        end

        def to_step_definition_arg
          self
        end

        def has_text?(text)
          index(text)
        end

        def ==(other)
          content == other.content && content_type == other.content_type
        end

        def encoding
          @content.encoding
        end

        def to_str
          @content
        end

        def gsub(*args)
          @content.gsub(*args)
        end

        private

        def description_for_visitors
          :doc_string
        end

      end
    end
  end
end
