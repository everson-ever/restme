# frozen_string_literal: true

module Restme
  module Shared
    # Returns the model associated with the controller.
    # It tries to determine the model dynamically or uses the MODEL_NAME constant if defined in the controller.
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
