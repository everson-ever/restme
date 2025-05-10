# frozen_string_literal: true

require_relative "../shared/user_role"
require_relative "../shared/current_model"
require_relative "../shared/controller_params"

module Restme
  module Create
    module Rules
      include ::Restme::Shared::ControllerParams
      include ::Restme::Shared::CurrentModel
      include ::Restme::Shared::UserRole

      attr_reader :create_temp_record

      private

      def creatable_record
        @creatable_record ||= begin
          @create_temp_record = klass.new(controller_params)

          set_create_temp_record_current_user

          create_record_errors.presence || create_temp_record
        end
      end

      def set_create_temp_record_current_user
        return unless create_temp_record.respond_to?(:current_user)
        return unless restme_current_user

        create_temp_record.current_user = restme_current_user
      end

      def restme_create_status
        return :unprocessable_entity if create_record_errors

        :created
      end

      def create_record_errors
        return unless creatable_current_action

        return createable_unscoped_error_response unless createable_scope?

        create_object! unless create_temp_record.persisted?

        createable_object_errors_messages
      end

      def create_object!
        ActiveRecord::Base.transaction do
          create_temp_record.save!
        end
      rescue StandardError
        nil
      end

      def createable_unscoped_error_response
        { message: "Unscoped", body: controller_params }
      end

      def createable_scope?
        return true unless restme_current_user

        method_scope = "#{creatable_current_action}_#{user_role}_scope?"

        createable_super_admin_scope? || create_rules_class.try(method_scope) || false
      end

      def createable_super_admin_scope?
        restme_current_user.super_admin?
      end

      def createable_object_errors_messages
        return if create_temp_record.errors.blank?

        "#{current_action}_error_scope?".constantize
      rescue StandardError
        createable_default_error_response
      end

      def creatable_current_action
        current_action.presence_in create_rules_class.class::CREATABLE_ACTIONS_RULES
      rescue StandardError
        nil
      end

      def current_action
        action_name.to_sym
      end

      def createable_default_error_response
        {
          message: "Error #{create_temp_record.errors.full_messages.to_sentence}",
          body: controller_params
        }
      end

      def create_rules_class
        @create_rules_class ||=
          "#{controller_class.to_s.split("::").last}::Create::Rules"
          .constantize.new(create_temp_record, restme_current_user)
      end
    end
  end
end
