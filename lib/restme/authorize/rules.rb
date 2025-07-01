# frozen_string_literal: true

require_relative "../shared/user_role"
require_relative "../shared/current_model"

module Restme
  module Authorize
    # Defines the rules used to authotize user
    module Rules
      include ::Restme::Shared::CurrentModel
      include ::Restme::Shared::UserRole

      def user_authorized?
        return true if restme_current_user.blank? || authorize?

        authorize_errors

        false
      end

      def authorize?
        super_authorize? ||
          allowed_roles_actions[action_name.to_sym]&.include?(user_role.to_sym)
      end

      def authorize_errors
        restme_scope_errors(
          {
            message: "Action not allowed",
            body: {}
          }
        )

        restme_scope_status(:forbidden)
      end

      def allowed_roles_actions
        return {} unless authorize_rules_class&.const_defined?(:ALLOWED_ROLES_ACTIONS)

        authorize_rules_class::ALLOWED_ROLES_ACTIONS
      end

      def super_authorize?
        restme_current_user&.super_admin?
      end

      def authorize_rules_class
        "#{controller_class.to_s.split("::").last}::Authorize::Rules".safe_constantize
      end
    end
  end
end
