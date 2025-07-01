# frozen_string_literal: true

module Restme
  # Defines the initialization configuration for restme gem
  module Configuration
    @restme_current_user_variable_name = :current_user
    @restme_current_user_role_field_name = :role
    @restme_pagination_default_per_page = 12
    @restme_pagination_default_page = 1
    @restme_pagination_default_max_per_page = 100

    class << self
      attr_accessor :restme_current_user_variable_name,
                    :restme_current_user_role_field_name,
                    :restme_pagination_default_per_page,
                    :restme_pagination_default_page,
                    :restme_pagination_default_max_per_page
    end
  end
end
