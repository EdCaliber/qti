require 'qti/v1/models/base'

module Qti
  module V1
    module Models
      class Assessment < Qti::V1::Models::Base
        def title
          @title ||= xpath_with_single_check('.//xmlns:assessment/@title').try(:content) || File.basename(@path, '.xml')
        end

        def assessment_items
          @doc.xpath('.//xmlns:item')
        end

        def create_assessment_item(assessment_item)
          item = Qti::V1::Models::AssessmentItem.new(assessment_item, @package_root)
          item.manifest = manifest
          item
        end

        def stimulus_ref(_ref)
          nil
        end

        def create_stimulus(_stimulus)
          raise 'Stimulus type not supported for QTI version'
        end
      end
    end
  end
end
