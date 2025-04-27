# Restme

## ⚠️ Do not use this gem yet. In progress

[![Gem Version](https://badge.fury.io/rb/restme.svg)](https://badge.fury.io/rb/restme)

Adds support for new controller actions such as pagination, filtering, sorting, and selecting specific model fields. Easily implement full CRUD functionality by importing Restme into your controller.

This gem manages your controller's responsibilities for:
- Read Actions: Providing complete pagination, filtering, sorting, and field selection for records.
- Create/Update Actions: Enabling automatic creation and updating of records.

## Installation



```bash
gem install restme
```

OR

```bash
gem 'restme', '~> 0.0.33'
```

## Usage

#### ℹ️ Current Version of gem require the following pré configs

 - Your models must include a current_user attribute (model.current_user). This attribute is used during create and update actions to set the user context at runtime, allowing it to be used in custom logic
 - Your controllers must be named using the plural form of the model (e.g., Product → ProductsController). Alternatively, you can manually set the model name by defining the MODEL_NAME constant (e.g., MODEL_NAME = "Shopping").
 - You must create a folder inside app named restfy to define controller rules for authorization, scoping, creation, updating, and field selection (see example below).


### Usage examples

- Controller example

```ruby
module Api::V1::Products
  class ProductsController < ApplicationController
    include Restme::Restme

    before_action :initialize_restme

    def index
      render json: pagination_response, status: restme_scope_status
    end

    def show
      render json: model_scope_object, status: restme_scope_status
    end

    def create
      render json: creatable_record, status: restme_create_status
    end

    def update
      render json: updateable_record, status: restme_update_status
    end
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Restme project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/restme/blob/master/CODE_OF_CONDUCT.md).
