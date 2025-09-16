# frozen_string_literal: true

require_relative "../shared/restme_current_user_role"
require_relative "../shared/current_model"
require_relative "../shared/controller_params"
require_relative "filter/rules"
require_relative "sort/rules"
require_relative "paginate/rules"
require_relative "field/rules"

module Restme
  module Scope
    # Defines the user scope when viewing records.
    # It can apply pagination, field selection, sorting, and filtering.
    # Returns records based on the user's contextual rules.
    module Rules
      include ::Restme::Scope::Field::Rules
      include ::Restme::Scope::Paginate::Rules
      include ::Restme::Scope::Sort::Rules
      include ::Restme::Scope::Filter::Rules
      include ::Restme::Shared::ControllerParams
      include ::Restme::Shared::CurrentModel
      include ::Restme::Shared::RestmeCurrentUserRole

      attr_reader :sortable_scope_response, :paginable_scope_response
      attr_writer :restme_scope_errors, :restme_scope_status

      SCOPE_ERROR_METHODS = %i[
        per_page_errors
        unknown_sortable_fields_errors
        unallowed_filter_fields_errors
        unallowed_select_fields_errors
      ].freeze

      def pagination_response
        @pagination_response ||= restme_pagination_response
      end

      def model_scope_object
        @model_scope_object ||= begin
          model_scope unless any_scope_errors.present?

          restme_scope_errors.presence || model_scope.first
        end
      end

      private

      def restme_pagination_response
        any_scope_errors

        restme_scope_errors.presence || {
          objects: model_scope,
          pagination: pagination
        }
      end

      def any_scope_errors
        SCOPE_ERROR_METHODS.each { |m| send(m) }

        restme_scope_errors
      end

      def model_scope
        @model_scope ||= custom_scope
      end

      def pagination
        {
          page: page_no,
          pages: pages(filterable_scope_response),
          total_items: total_items(filterable_scope_response)
        }
      end

      def restme_scope_errors(error = nil)
        @restme_scope_errors ||= []
        @restme_scope_errors << error if error.present?
        @restme_scope_errors
      end

      def restme_scope_status(status = :ok)
        @restme_scope_status ||= status
      end

      def custom_scope
        return filterable_scope_response if filterable_scope_response.blank?

        @sortable_scope_response = sortable_scope(filterable_scope_response)
        @paginable_scope_response = paginable_scope(sortable_scope_response)

        fieldable_scope(paginable_scope_response)
      end

      def filterable_scope_response
        @filterable_scope_response ||= filterable_scope(user_scope)
      end

      def user_scope
        @user_scope ||= none_user_scope || scope_rules_class.try(method_scope) || none_scope
      end

      def none_user_scope
        klass.all if restme_current_user.blank?
      end

      def none_scope
        klass.none
      end

      def method_scope
        "#{restme_current_user_role}_scope"
      end

      def scope_rules_class
        "#{controller_class.to_s.split("::").last}::Scope::Rules"
          .constantize.new(klass, restme_current_user, params)
      end
    end
  end
end
