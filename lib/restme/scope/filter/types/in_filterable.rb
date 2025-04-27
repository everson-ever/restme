# frozen_string_literal: true

module Scope
  module Filter
    module Types
      module InFilterable
        FIELD_SUFFIX = :in

        private

        def where_in(scope)
          return scope if in_fields.blank?

          serialize_in_fields

          scope.where(in_sql, in_fields)
        end

        def in_sql
          in_fields.keys.map do |param|
            "#{klass.table_name}.#{param} IN (:#{param})"
          end.join(" AND ")
        end

        def serialize_in_fields
          in_fields.each do |key, value|
            in_fields[key] = value.split(",")
          end
        end

        def add_in_field(field)
          field_key = :"#{field}_#{FIELD_SUFFIX}"
          field_value = controller_query_params[field_key]
          in_fields[field] = field_value if field_value

          field_key
        end

        def in_fields
          params_filters[FIELD_SUFFIX] ||= {}
        end
      end
    end
  end
end
