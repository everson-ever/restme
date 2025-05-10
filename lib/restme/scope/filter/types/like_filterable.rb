# frozen_string_literal: true

module Scope
  module Filter
    module Types
      # Defines the behavior of "like" filters used for partial matching in queries.
      module LikeFilterable
        FIELD_SUFFIX = :like

        private

        def where_like(scope)
          return scope if like_fields.blank?

          scope.where(like_sql, like_fields)
        end

        def like_sql
          like_fields.keys.map do |param|
            "CAST(#{klass.table_name}.#{param} AS TEXT) ILIKE :#{param}"
          end.join(" AND ")
        end

        def add_like_field(field)
          field_key = :"#{field}_#{FIELD_SUFFIX}"
          field_value = controller_query_params[field_key].to_s

          field_value = "%#{field_value}%" if field_value.present?
          like_fields[field] = field_value if field_value.present?

          field_key
        end

        def like_fields
          params_filters[FIELD_SUFFIX] ||= {}
        end
      end
    end
  end
end
