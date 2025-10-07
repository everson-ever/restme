# frozen_string_literal: true

module Restme
  module Shared
    # Returns the roles associated with the user, always normalized as an Array of symbols.
    module RestmeCurrentUserRoles
      def restme_current_user_roles
        Array.wrap(user_roles).map do |role|
          role.respond_to?(:to_sym) ? role.to_sym : role.to_s.to_sym
        end
      end

      def user_roles
        @user_roles ||= restme_current_user&.try(::Restme::Configuration.user_role_field)
      end
    end
  end
end
