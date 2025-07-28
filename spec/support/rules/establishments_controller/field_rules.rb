# frozen_string_literal: true

class EstablishmentsController
  module Field
    class Rules
      NESTED_SELECTABLE_FIELDS = {
        setting: {
          table_name: :settings,
          join_type: :left_joins
        },
        products: {
          table_name: :products
        }
      }.freeze
    end
  end
end
