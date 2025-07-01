# frozen_string_literal: true

module Restme
  module Shared
    # Returns the roles associated with the user, if any exist.
    module RestmeCurrentUserRole
      def restme_current_user_role
        restme_current_user&.try(::Restme::Configuration.current_user_role_field_name)
      end
    end
  end
end
