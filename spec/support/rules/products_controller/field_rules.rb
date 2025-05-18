# frozen_string_literal: true

class ProductsController
  module Field
    class Rules
      NESTED_SELECTABLE_FIELDS = {
        establishment: {
          table_name: :establishments
        }
      }.freeze
    end
  end
end
