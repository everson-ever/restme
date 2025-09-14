# frozen_string_literal: true

module Restme
  module Scope
    module Field
      # Defines the rules that determine which attachable fields can be attached.
      module Attachable
        def insert_attachments(scope)
          unallowed_attachment_fields_error

          return scope.as_json(json_options) if attachment_fields_select.blank?

          define_attachment_methods

          scope.includes(attachment_fields_select_includes)
               .as_json(json_options)
        end

        def json_options
          {
            include: valid_nested_fields_select,
            methods: attachment_methods
          }
        end

        def define_attachment_methods
          attachment_fields_select.each do |attachment_field_name|
            klass.class_eval do
              define_method(:"#{attachment_field_name}_url") do
                send(attachment_field_name).url
              end
            end
          end
        end

        def attachment_methods
          attachment_fields_select&.map { |field| "#{field}_url" }
        end

        def attachment_fields_select_includes
          attachment_fields_select.map { |field| { "#{field}_attachment": :blob } }
        end

        def model_attachment_fields
          @model_attachment_fields ||= klass.attachment_reflections.map do |attachment|
            attachment.last.name
          end
        end

        def unallowed_attachment_fields_error
          return if unallowed_attachment_fields.blank?

          render json: {
            body: unallowed_attachment_fields,
            message: "Selected not allowed attachment fields"
          }, status: :bad_request
        end

        def unallowed_attachment_fields
          return if attachment_fields_select.blank?

          attachment_fields_select - model_attachment_fields
        end
      end
    end
  end
end
