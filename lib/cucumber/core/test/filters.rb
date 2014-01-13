module Cucumber
  module Core
    module Test

      class LocationsFilter
        def initialize(locations, receiver)
          @receiver = receiver
          @locations = locations
        end

        def test_case(test_case)
          if test_case.match_locations?(@locations)
            test_case.describe_to @receiver
          end
          self
        end
      end

      class NameFilter
        include Cucumber.initializer(:name_regexps, :receiver)

        def test_case(test_case)
          if accept?(test_case)
            test_case.describe_to(receiver)
          end
          self
        end

        private

        def accept?(test_case)
          name_regexps.empty? || name_regexps.any? { |name_regexp| test_case.match_name?(name_regexp) }
        end
      end

      class TagFilter
        include Cucumber.initializer(:filter_expressions, :receiver)
        attr_reader :tag_counter, :tag_limits
        private :tag_counter, :tag_limits

        class TagCounter
          attr_reader :tag_list, :tag_name_counts
          private :tag_list, :tag_name_counts
          def initialize
            @tag_list = Set.new #Make sure that we only collect unique tags
            @tag_name_counts = Hash.new { 0 }
          end

          def count(*tags)
            tag_list.merge tags
            tags.each do |tag|
              tag_name_counts[tag.name] += 1
            end
            self
          end

          def count_for(tag_name)
            tag_name_counts[tag_name]
          end

          def locations_for(tag_name)
            tag_list.select { |tag| tag.name == tag_name }.map(&:location)
          end

        end

        class TagLimits
          attr_reader :limit_list
          private :limit_list
          def initialize(filter_expressions)
            @limit_list = Hash[
              filter_expressions.map{ |filter_expression|
                if matchdata = filter_expression.match(/^(\@[\w\d]+)\:(\d+)$/)
                  [matchdata[1], Integer(matchdata[2])]
                end
              }.compact
            ]
          end

          def enforce(tag_counter)
            limit_breaches = limit_list.reduce([]) do |breaches, (tag_name, limit)|
              tag_count = tag_counter.count_for(tag_name)
              if tag_count > limit
                tag_locations = tag_counter.locations_for(tag_name)
                breaches << TagLimitBreach.new(
                  tag_count,
                  limit,
                  tag_name,
                  tag_locations
                )
              end
              breaches
            end
            raise TagExcess.new(limit_breaches) if !limit_breaches.empty?
          end
        end

        class TagLimitBreach
          include Cucumber.initializer(
            :tag_count,
            :tag_limit,
            :tag_name,
            :tag_locations
          )

          def message
            "#{tag_name} occurred #{tag_count} times, but the limit was set to #{tag_limit}\n  " +
              tag_locations.join("\n  ")
          end
          alias :to_s :message
        end

        class TagExcess < StandardError
          def initialize(limit_breaches)
            super(limit_breaches.map(&:to_s).join("\n"))
          end
        end

        def test_suite_started
          puts 'called'
          @tag_counter = TagCounter.new
          @tag_limits = TagLimits.new(filter_expressions)
          self
        end

        def test_case(test_case)
          if test_case.match_tags?(filter_expressions)
            tag_counter.count(*test_case.tags)
            test_case.describe_to(receiver)
          end
          self
        end

        def test_suite_finished
          tag_limits.enforce(tag_counter)
          self
        end

      end

    end
  end
end
