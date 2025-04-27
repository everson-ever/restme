# frozen_string_literal: true

module Restme
  module Shared
    module CurrentModel
      def klass
        return defined_model_name if defined_model_name

        controller_class.to_s.split("::").last.remove("sController").constantize
      end

      private

      def defined_model_name
        return unless controller_class.const_defined?(:MODEL_NAME)

        controller_class::MODEL_NAME.constantize
      end

      def controller_class
        self.class
      end
    end
  end
end
