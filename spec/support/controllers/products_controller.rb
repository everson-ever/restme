# frozen_string_literal: true

class ProductsController
  include Restme::Restme

  attr_accessor :params, :request, :current_user
  attr_reader :action_name

  Restme.configure do |config|
    config.current_user_variable_name = :current_user
    config.current_user_role_field_name = :role
  end

  class AuthorizationError < StandardError
    attr_reader :json, :status

    def initialize(json: {}, status: nil)
      @json = json
      @status = status

      super
    end
  end

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
  rescue AuthorizationError => e
    authorization_erro(e)
  end

  def show
    @action_name = "show"

    initialize_restme

    {
      body: model_scope_object.as_json,
      status: restme_scope_status
    }
  rescue AuthorizationError => e
    authorization_erro(e)
  end

  def render(json: {}, status: nil)
    return unless status == :forbidden

    raise AuthorizationError.new(json: json, status: status)
  end

  def authorization_erro(error)
    {
      body: error.json.as_json,
      status: error.status
    }
  end
end
