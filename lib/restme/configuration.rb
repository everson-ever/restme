# frozen_string_literal: true

module Restme
  # Defines the initialization configuration for restme gem
  module Configuration
    @current_user_variable_name = :current_user
    @current_user_role_field_name = :role

    class << self
      attr_accessor :current_user_variable_name, :current_user_role_field_name
    end
  end
end
