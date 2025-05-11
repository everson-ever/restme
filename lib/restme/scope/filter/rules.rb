# frozen_string_literal: true

require_relative "types/equal_filterable"
require_relative "types/like_filterable"
require_relative "types/bigger_than_filterable"
require_relative "types/less_than_filterable"
require_relative "types/bigger_than_or_equal_to_filterable"
require_relative "types/less_than_or_equal_to_filterable"
require_relative "types/in_filterable"

module Restme
  module Scope
    module Filter
      # Defines filter rules
      module Rules
        include ::Scope::Filter::Types::InFilterable
        include ::Scope::Filter::Types::LessThanOrEqualToFilterable
        include ::Scope::Filter::Types::BiggerThanOrEqualToFilterable
        include ::Scope::Filter::Types::LessThanFilterable
        include ::Scope::Filter::Types::BiggerThanFilterable
        include ::Scope::Filter::Types::LikeFilterable
        include ::Scope::Filter::Types::EqualFilterable

        ID = :id

        FILTERS_TYPES = %i[
          equal
          like
          bigger_than
          less_than
          bigger_than_or_equal_to
          less_than_or_equal_to
          in
        ].freeze

        private

        def filterable_scope(user_scope)
          return user_scope unless filterable_scope?
          return user_scope if unallowed_filter_fields_errors

          next_scope = where_equal(user_scope)
          next_scope = where_like(next_scope)
          next_scope = where_bigger_than(next_scope)
          next_scope = where_less_than(next_scope)
          next_scope = where_bigger_than_or_equal_to(next_scope)
          next_scope = where_less_than_or_equal_to(next_scope)
          where_in(next_scope)
        end

        def allowed_fields
          @allowed_fields ||= controller_params_filters_fields.map do |param_key|
            filter_type = FILTERS_TYPES.find do |filter_type|
              param_key.to_s.end_with?(filter_type.to_s)
            end

            record_field = param_key.to_s.gsub("_#{filter_type}", "")&.to_sym

            next unless filter_type
            next unless filteable_fields.include?(record_field)

            send(:"add_#{filter_type}_field", record_field)
          end.compact.flatten
        end

        def params_filters
          @params_filters ||= {}
        end

        def filteable_fields
          @filteable_fields ||= Array.new(klass::FILTERABLE_FIELDS).push(ID)
        rescue StandardError
          [ID]
        end

        def filterable_scope?
          try_insert_id_equal

          request.get? && controller_params_filters_fields.present?
        end

        def try_insert_id_equal
          return if params[:id].blank?

          controller_params_filters_fields.push(:id_equal)
        end

        def unallowed_filter_fields_errors
          return unless unallowed_fields_to_filter.present?

          restme_scope_errors(
            {
              message: "Unknown Filter Fields",
              body: unallowed_fields_to_filter
            }
          )

          restme_scope_status(:bad_request)

          true
        end

        def unallowed_fields_to_filter
          @unallowed_fields_to_filter ||= controller_params_filters_fields - allowed_fields
        end

        def controller_params_filters_fields
          @controller_params_filters_fields ||= controller_query_params.keys.select do |item|
            FILTERS_TYPES.any? { |filter| item.to_s.end_with?(filter.to_s) }
          end
        end
      end
    end
  end
end
