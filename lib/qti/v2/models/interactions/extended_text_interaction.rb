module Qti
  module V2
    module Models
      module Interactions
        class ExtendedTextInteraction < BaseInteraction
          # This will know if a class matches
          def self.matches(node, parent)
            matches = node.xpath('.//xmlns:extendedTextInteraction')
            return false if matches.empty?

            raise Qti::UnsupportedSchema if matches.size > 1
            new(matches.first, parent)
          end

          # not used yet
          def expected_lines
            @node.attributes['expectedLines'].try(:value).try(:to_i) || 0
          end

          def max_strings
            @node.attributes['maxStrings'].try(:value).try(:to_i)
          end

          def min_strings
            @node.attributes['minStrings'].try(:value).try(:to_i) || 0
          end
        end
      end
    end
  end
end
