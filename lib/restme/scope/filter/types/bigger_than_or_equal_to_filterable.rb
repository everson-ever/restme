# frozen_string_literal: true

module Scope
  module Filter
    module Types
      module BiggerThanOrEqualToFilterable
        FIELD_SUFFIX = :bigger_than_or_equal_to

        private

        def where_bigger_than_or_equal_to(scope)
          return scope if bigger_than_or_equal_to_fields.blank?

          scope.where(bigger_than_or_equal_to_sql, bigger_than_or_equal_to_fields)
        end

        def bigger_than_or_equal_to_sql
          bigger_than_or_equal_to_fields.keys.map do |param|
            "#{klass.table_name}.#{param} >= :#{param}"
          end.join(" AND ")
        end

        def add_bigger_than_or_equal_to_field(field)
          field_key = :"#{field}_#{FIELD_SUFFIX}"
          field_value = controller_query_params[field_key]
          bigger_than_or_equal_to_fields[field] = field_value if field_value

          field_key
        end

        def bigger_than_or_equal_to_fields
          params_filters[FIELD_SUFFIX] ||= {}
        end
      end
    end
  end
end
