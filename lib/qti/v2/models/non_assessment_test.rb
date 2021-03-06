require 'qti/v2/models/base'

module Qti
  module V2
    module Models
      class NonAssessmentTest < Qti::V2::Models::AssessmentTest
        def assessment_items
          # Return the xml files we should be parsing
          @assessment_item_reference_hrefs ||= begin
            hrefs.map do |href|
              remap_href_path(href)
            end
          end
        end

        def stimulus_ref(assessment_item_ref)
          ref = assessment_item_ref.sub(@package_root, '')
          dependencies = @doc.xpath("//xmlns:resource[@href='#{ref}']/xmlns:dependency/@identifierref")
          return unless dependencies.try(:count) == 1
          href = xpath_with_single_check("//xmlns:resource[@identifier='#{dependencies.first}']/@href")
          remap_href_path(href)
        end

        def hrefs
          nodes = @doc.xpath("//xmlns:resource[@type='imsqti_item_xmlv2p2']/@href")
          return nodes if nodes.count >= 1
          @doc.xpath("//xmlns:resource[@type='imsqti_item_xmlv2p1']/@href")
        end
      end
    end
  end
end
