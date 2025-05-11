# frozen_string_literal: true

module Scope
  module Filter
    module Types
      # Defines the behavior of the "less than or equal to" filter in queries.
      module LessThanOrEqualToFilterable
        FIELD_SUFFIX = :less_than_or_equal_to

        private

        def where_less_than_or_equal_to(scope)
          return scope if less_than_or_equal_to_fields.blank?

          scope.where(less_than_or_equal_to_sql, less_than_or_equal_to_fields)
        end

        def less_than_or_equal_to_sql
          less_than_or_equal_to_fields.keys.map do |param|
            "#{klass.table_name}.#{param} <= :#{param}"
          end.join(" AND ")
        end

        def add_less_than_or_equal_to_field(field)
          field_key = :"#{field}_#{FIELD_SUFFIX}"
          field_value = controller_query_params[field_key]
          less_than_or_equal_to_fields[field] = field_value if field_value

          field_key
        end

        def less_than_or_equal_to_fields
          params_filters[FIELD_SUFFIX] ||= {}
        end
      end
    end
  end
end
