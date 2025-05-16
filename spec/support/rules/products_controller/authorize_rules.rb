# frozen_string_literal: true

class ProductsController
  module Authorize
    class Rules
      ALLOWED_ROLES_ACTIONS = {
        index: %i[client manager],
        show: %i[client manager]
      }.freeze
    end
  end
end
