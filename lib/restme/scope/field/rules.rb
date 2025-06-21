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
        end

        def select_nested_scope(scoped)
          scoped.joins(nested_fields_joins)
                .left_joins(nested_fields_left_joins)
                .preload(valid_nested_fields_select)
                .select(nesteds_table)
        end

        def select_any_field?
          fields_select || nested_fields_select || attachment_fields_select
        end

        def nesteds_table
          valid_nested_fields_select&.map do |field|
            table = nested_selectable_fields_keys.dig(field, :table_name)
            table.present? ? "#{table}::text AS #{field}" : nil
          end
        end

        def model_fields_select
          @model_fields_select ||= begin
            fields = fields_select&.split(",")
            fields = fields&.map { |field| "#{klass.table_name}.#{field}" }&.join(",")
            fields || model_attributes
          end
        end

        def model_attributes
          @model_attributes ||= klass.new.attributes.keys
        end

        def nested_fields_joins
          @nested_fields_joins ||= valid_nested_fields_select.select do |field|
            nested_selectable_fields_keys[field.to_sym][:join_type].blank?
          end
        end

        def nested_fields_left_joins
          @nested_fields_left_joins ||= valid_nested_fields_select.select do |field|
            nested_selectable_fields_keys[field.to_sym][:join_type] == :left_joins
          end
        end

        def valid_nested_fields_select
          @valid_nested_fields_select ||=
            nested_fields_select&.split(",")&.select do |field|
              nested_selectable_fields_keys[field.to_sym].present?
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
          @fields_select ||= controller_query_params[:fields_select]
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
