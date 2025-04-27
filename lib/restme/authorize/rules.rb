# frozen_string_literal: true

require_relative "../shared/user_role"
require_relative "../shared/current_model"

module Restme
  module Authorize
    module Rules
      include ::Restme::Shared::CurrentModel
      include ::Restme::Shared::UserRole

      def user_authorize
        return if super_authorize? || allowed_roles_actions[action_name.to_sym]&.include?(user_role.to_sym)

        render json: { message: "Action not allowed" }, status: :forbidden
      end

      def allowed_roles_actions
        return {} unless authorize_rules_class.const_defined?(:ALLOWED_ROLES_ACTIONS)

        authorize_rules_class::ALLOWED_ROLES_ACTIONS
      end

      def super_authorize?
        current_user.super_admin?
      end

      def authorize_rules_class
        "#{controller_class.to_s.split("::").last}::Authorize::Rules".constantize
      end
    end
  end
end
