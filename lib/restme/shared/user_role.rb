# frozen_string_literal: true

module Restme
  module Shared
    module UserRole
      def user_role
        current_user.role
      end
    end
  end
end
