# frozen_string_literal: true

class RequestMock
  attr_accessor :http_method, :query_parameters

  def initialize(http_method: "get", query_parameters: {})
    @http_method = http_method
    @query_parameters = query_parameters.as_json
  end

  def get?
    http_method.to_sym == :get
  end
end
