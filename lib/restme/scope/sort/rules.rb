# frozen_string_literal: true

module Restme
  module Scope
    module Sort
      module Rules
        ID = :id
        SORT_KEY = "sort"
        SORTABLE_TYPES = %w[asc desc].freeze

        # before_action :unknown_sortable_fields_response, if: :unknown_sortable_fields?

        def sortable_scope(user_scope)
          return user_scope unless sortable_scope?

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

        def unknown_sortable_fields?
          unknown_sortable_fields.present?
        end

        def unknown_sortable_fields_response
          render json: { message: "Unknown Sort", body: unknown_sortable_fields },
                 status: :bad_request
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
