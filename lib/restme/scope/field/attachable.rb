# frozen_string_literal: true

module Restme
  module Scope
    module Field
      # Defines the rules that determine which attachable fields can be attached.
      module Attachable
        def insert_attachments(scope)
          unallowed_attachment_fields_error

          return scope.uniq if attachment_fields_select.blank?

          scope = scope.includes(attachment_fields_select_includes).uniq

          scope.map do |record|
            attachment_fields_select.each do |field|
              @record = record.as_json.merge({ "#{field}": record.send(field).url })
            end

            @record
          end
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
