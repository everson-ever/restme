# frozen_string_literal: true

module Restme
  module Shared
    # Returns the roles associated with the user, if any exist.
    module UserRole
      def restme_current_user_role
        restme_current_user&.try(:role)
      end
    end
  end
end
