# frozen_string_literal: true

module Scope
  module Filter
    module Types
      # Defines the behavior of the "bigger than" filter in queries.
      module BiggerThanFilterable
        FIELD_SUFFIX = :bigger_than

        private

        def where_bigger_than(scope)
          return scope if bigger_than_fields.blank?

          scope.where(bigger_than_sql, bigger_than_fields)
        end

        def bigger_than_sql
          bigger_than_fields.keys.map do |param|
            "#{klass.table_name}.#{param} > :#{param}"
          end.join(" AND ")
        end

        def add_bigger_than_field(field)
          field_key = :"#{field}_#{FIELD_SUFFIX}"
          field_value = controller_query_params[field_key]
          bigger_than_fields[field] = field_value if field_value

          field_key
        end

        def bigger_than_fields
          params_filters[FIELD_SUFFIX] ||= {}
        end
      end
    end
  end
end
