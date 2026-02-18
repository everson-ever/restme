# frozen_string_literal: true

require_relative "attachable"

module Restme
  module Scope
    module Field
      # Defines the rules that determine which fields can be attached.
      module Rules
        include Restme::Scope::Field::Attachable

        def fieldable_scope(user_scope)
          return user_scope unless select_any_field?

          scoped = user_scope

          scoped = user_scope.select(model_fields_select) if model_fields_select

          scoped = select_nested_scope(scoped) if valid_nested_fields_select

          insert_attachments(scoped)
        rescue ActiveModel::MissingAttributeError => e
          restme_scope_errors({ body: model_fields_select, message: e.message })

          restme_scope_status(:bad_request)
        end

        def select_nested_scope(scoped)
          scoped.preload(valid_nested_fields_select)
        end

        def select_any_field?
          defined_fields_select || fields_select || nested_fields_select || attachment_fields_select
        end

        def model_fields_select
          @model_fields_select ||= select_selected_fields.presence || model_attributes
        end

        def select_selected_fields
          @select_selected_fields ||= defined_fields_select | fields_select.split(",").map(&:to_s)
        end

        def model_attributes
          @model_attributes ||= klass.attribute_names - unallowed_model_fields_select
        end

        def defined_fields_select
          return [] unless field_class_rules&.const_defined?(:MODEL_FIELDS_SELECT)

          (field_class_rules::MODEL_FIELDS_SELECT || []).map(&:to_s)
        end

        def unallowed_model_fields_select
          return [] unless field_class_rules&.const_defined?(:UNALLOWED_MODEL_FIELDS_SELECT)

          (field_class_rules::UNALLOWED_MODEL_FIELDS_SELECT || []).map(&:to_s)
        end

        def valid_nested_fields_select
          @valid_nested_fields_select ||=
            nested_fields_select&.split(",")&.select do |field|
              nested_selectable_fields_keys.key?(field.to_sym)
            end&.map(&:to_sym)
        end

        def unallowed_select_fields_errors
          return if unallowed_fields_selected.blank?

          restme_scope_errors({ body: unallowed_fields_selected, message: "Selected not allowed fields" })

          restme_scope_status(:bad_request)

          true
        end

        def unallowed_fields_selected
          unallowed_nested_fields_select + unallowed_fields_select
        end

        def unallowed_nested_fields_select
          return [] if nested_fields_select.blank?

          nested_fields_select.split(",").map(&:to_sym) - valid_nested_fields_select
        end

        def unallowed_fields_select
          return [] if fields_select.blank?

          fields_select.split(",").map(&:to_sym) - model_attributes.map(&:to_sym)
        end

        def fields_select
          @fields_select ||= controller_query_params[:fields_select] || ""
        end

        def nested_fields_select
          @nested_fields_select ||= controller_query_params[:nested_fields_select]
        end

        def attachment_fields_select
          @attachment_fields_select ||= controller_query_params[:attachment_fields_select]
                                        &.split(",")&.map(&:to_sym)
        end

        def nested_selectable_fields_keys
          @nested_selectable_fields_keys ||= field_class_rules::NESTED_SELECTABLE_FIELDS
        rescue StandardError
          {}
        end

        def field_class_rules
          "#{controller_class.to_s.split("::").last}::Field::Rules".constantize
        end
      end
    end
  end
end
