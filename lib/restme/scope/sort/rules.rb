# frozen_string_literal: true

module Restme
  module Scope
    module Sort
      # Defines the rules used to sort the records.
      module Rules
        ID = :id
        SORT_KEY = "sort"
        SORTABLE_TYPES = %w[asc desc].freeze

        def sortable_scope(user_scope)
          return user_scope unless sortable_scope?
          return user_scope if unknown_sortable_fields_errors

          user_scope.order(serialize_sort_params)
        end

        def sortable_scope?
          request.get? && controller_params_sortable_fields.present?
        end

        def serialize_sort_params
          @serialize_sort_params ||= controller_params_sortable_fields.map do |key, value|
            key = key.to_s.gsub("_#{SORT_KEY}", "")

            value = "asc" unless SORTABLE_TYPES.include?(value&.downcase)

            { "#{key}": value&.downcase }
          end
        end

        def controller_params_sortable_fields
          @controller_params_sortable_fields ||= controller_query_params.select do |item|
            item.to_s.end_with?(SORT_KEY)
          end
        end

        def unknown_sortable_fields
          @unknown_sortable_fields ||=
            serialize_sort_params.map { |sort_param| sort_param.first.first } - sortable_fields
        end

        def unknown_sortable_fields_errors
          return unless unknown_sortable_fields.present?

          restme_scope_errors(
            {
              message: "Unknown Sort",
              body: unknown_sortable_fields
            }
          )

          restme_scope_status(:bad_request)

          true
        end

        def sortable_fields
          @sortable_fields ||= Array.new(klass::SORTABLE_FIELDS).push(ID)
        rescue StandardError
          [ID]
        end
      end
    end
  end
end
