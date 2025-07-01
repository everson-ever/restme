# frozen_string_literal: true

require_relative "restme/version"
require_relative "restme/configuration"
require_relative "restme/restme"

# Restme gem
module Restme
  class Error < StandardError; end
  # Your code goes here...

  def self.configure
    yield(Configuration)
  end
end
