# frozen_string_literal: true

require_relative "authorize/rules"
require_relative "scope/rules"
require_relative "create/rules"
require_relative "update/rules"

module Restme
  module Restme
    include ::Restme::Update::Rules
    include ::Restme::Create::Rules
    include ::Restme::Scope::Rules
    include ::Restme::Authorize::Rules

    private

    def initialize_restme
      user_authorize
    end
  end
end
