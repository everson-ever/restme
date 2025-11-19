# frozen_string_literal: true

class ProductsController
  module Scope
    class Rules
      def initialize(klass, current_user, controller_params = {})
        @klass = klass
        @current_user = current_user
        @controller_params = controller_params
      end

      def client_scope
        @klass.all
      end

      def manager_scope
        @klass.all
      end

      def super_admin_scope
        @klass.all
      end
    end
  end
end
