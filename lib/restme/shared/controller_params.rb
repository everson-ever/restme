# frozen_string_literal: true

module Restme
  module Shared
    # Returns both the query string parameters and the request body parameters received by the controller.
    module ControllerParams
      def controller_params
        params_filtered.permit!.to_h.values.first.deep_symbolize_keys
      rescue StandardError
        params_filtered.permit!.to_h.deep_symbolize_keys
      end

      def controller_query_params
        @controller_query_params ||= request.query_parameters.deep_symbolize_keys
      end

      private

      def params_filtered
        params.except(:controller, :action)
      end
    end
  end
end
