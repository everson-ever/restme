# frozen_string_literal: true

class ProductsController
  include Restme::Restme

  attr_accessor :params, :request, :current_user
  attr_reader :action_name

  def initialize(current_user: nil, request: {}, params: {})
    @current_user = current_user
    @request = request
    @params = params
  end

  def index
    @action_name = "index"

    initialize_restme

    {
      body: pagination_response.as_json,
      status: restme_scope_status
    }
  end

  def show
    @action_name = "show"

    initialize_restme

    {
      body: model_scope_object.as_json,
      status: restme_scope_status
    }
  end
end
