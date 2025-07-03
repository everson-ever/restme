# frozen_string_literal: true

require_relative "authorize/rules"
require_relative "scope/rules"
require_relative "create/rules"
require_relative "update/rules"

module Restme
  # Defines the initialization rules for Restme.
  module Restme
    include ::Restme::Update::Rules
    include ::Restme::Create::Rules
    include ::Restme::Scope::Rules
    include ::Restme::Authorize::Rules

    attr_reader :restme_current_user

    def initialize_restme
      use_current_user

      restme_authorize_response unless user_authorized?
    end

    private

    def restme_authorize_response
      render json: restme_scope_errors, status: restme_scope_status
    end

    def use_current_user
      @restme_current_user =
        try(::Restme::Configuration.current_user_variable)
    end
  end
end
