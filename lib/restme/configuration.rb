# frozen_string_literal: true

module Restme
  # Defines the initialization configuration for restme gem
  module Configuration
    @current_user_variable = :current_user
    @user_role_field = :role
    @pagination_default_per_page = 12
    @pagination_default_page = 1
    @pagination_max_per_page = 100

    class << self
      attr_accessor :current_user_variable,
                    :user_role_field,
                    :pagination_default_per_page,
                    :pagination_default_page,
                    :pagination_max_per_page
    end
  end
end
