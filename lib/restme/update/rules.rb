# frozen_string_literal: true

require_relative "../shared/user_role"
require_relative "../shared/current_model"
require_relative "../shared/controller_params"

module Restme
  module Update
    module Rules
      include ::Restme::Shared::ControllerParams
      include ::Restme::Shared::CurrentModel
      include ::Restme::Shared::UserRole

      attr_reader :update_temp_record

      private

      def updateable_record
        @updateable_record ||= begin
          @update_temp_record = klass.find_by(id: params[:id])

          set_update_temp_record_current_user

          update_temp_record.assign_attributes(controller_params)

          update_record_errors.presence || update_temp_record
        end
      end

      def set_update_temp_record_current_user
        return unless update_temp_record.respond_to?(:current_user)
        return unless restme_current_user

        update_temp_record.current_user = restme_current_user
      end

      def restme_update_status
        return :unprocessable_entity if update_record_errors

        :ok
      end

      def update_record_errors
        return unless updateable_current_action

        return updateable_not_found_error if update_temp_record.blank?
        return updateable_unscoped_error_response unless updateable_scope?

        update_object! unless @update_result

        updateable_record_errors_messages
      end

      def update_object!
        @update_result ||= ActiveRecord::Base.transaction do
          update_temp_record.save!
        end
      rescue StandardError
        nil
      end

      def updateable_not_found_error
        {
          message: "Not found object to id: #{params[:id]}",
          body: controller_params
        }
      end

      def updateable_unscoped_error_response
        { message: "Unscoped", body: controller_params }
      end

      def updateable_scope?
        method_scope = "#{updateable_current_action}_#{user_role}_scope?"

        updateable_super_admin_scope? || update_rules_class.try(method_scope) || false
      end

      def updateable_super_admin_scope?
        restme_current_user&.super_admin?
      end

      def updateable_record_errors_messages
        return if update_temp_record.errors.blank?

        "#{current_action}_error_scope?".constantize
      rescue StandardError
        updateable_default_error_response
      end

      def updateable_current_action
        current_action.presence_in update_rules_class.class::UPDATABLE_ACTIONS_RULES
      rescue StandardError
        nil
      end

      def updateable_default_error_response
        { message: "Error #{update_temp_record.errors.full_messages.to_sentence}" }
      end

      def current_action
        action_name.to_sym
      end

      def update_rules_class
        @update_rules_class ||= "#{controller_class.to_s.split("::").last}::Update::Rules"
                                .constantize.new(update_temp_record, restme_current_user, controller_params)
      end
    end
  end
end
