# frozen_string_literal: true

module Scope
  module Filter
    module Types
      # Defines the behavior of the "equal" filter in queries.
      module EqualFilterable
        FIELD_SUFFIX = :equal

        private

        def where_equal(scope)
          return scope if equal_fields.blank?

          scope.where(equal_sql, equal_fields)
        end

        def equal_sql
          equal_fields.keys.map do |param|
            "#{klass.table_name}.#{param} = :#{param}"
          end.join(" AND ")
        end

        def add_equal_field(field)
          field_key = :"#{field}_#{FIELD_SUFFIX}"
          field_value = controller_query_params[field_key] || params[field]
          equal_fields[field] = field_value if field_value

          field_key
        end

        def equal_fields
          params_filters[FIELD_SUFFIX] ||= {}
        end
      end
    end
  end
end
