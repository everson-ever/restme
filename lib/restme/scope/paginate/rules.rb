# frozen_string_literal: true

module Restme
  module Scope
    module Paginate
      # Defines pagination rules
      module Rules
        DEFAULT_PER_PAGE = ::Restme::Configuration.restme_pagination_default_per_page
        DEFAULT_PAGE = ::Restme::Configuration.restme_pagination_default_page
        MAX_PER_PAGE = ::Restme::Configuration.restme_pagination_default_max_per_page

        def paginable_scope(user_scope)
          user_scope.limit(per_page).offset(paginate_offset)
        end

        def page_no
          params[:page]&.to_i || DEFAULT_PAGE
        end

        def pages(user_scope)
          (total_items(user_scope) / per_page.to_f).ceil
        end

        def total_items(user_scope)
          @total_items ||= user_scope.size
        end

        def per_page
          params[:per_page]&.to_i || DEFAULT_PER_PAGE
        end

        def paginate_offset
          (page_no - 1) * per_page
        end

        def per_page_errors
          return if per_page <= MAX_PER_PAGE

          restme_scope_errors(
            {
              message: "Invalid per page value",
              body: { per_page_max_value: MAX_PER_PAGE }
            }
          )

          restme_scope_status(:bad_request)

          true
        end
      end
    end
  end
end
