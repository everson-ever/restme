# frozen_string_literal: true

class ProductsController
  module Authorize
    class Rules
      ALLOWED_ROLES_ACTIONS = {
        index: %i[super_admin client manager],
        show: %i[super_admin client manager]
      }.freeze
    end
  end
end
