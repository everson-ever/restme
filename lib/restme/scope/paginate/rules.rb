# frozen_string_literal: true

module Restme
  module Scope
    module Paginate
      module Rules
        DEFAULT_PER_PAGE = ENV.fetch("PAGINATION_DEFAULT_PER_PAGE", 12)
        DEFAULT_PAGE = ENV.fetch("PAGINATION_DEFAULT_PAGE", 1)
        MAX_PER_PAGE = ENV.fetch("PAGINATION_MAX_PER_PAGE", 100)

        def paginable_scope(user_scope)
          per_page_error

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

        def per_page_error
          return if per_page <= MAX_PER_PAGE

          restme_scope_errors(
            {
              message: "Invalid per page value",
              body: { per_page_max_value: MAX_PER_PAGE }
            }
          )

          restme_scope_status(:bad_request)
        end
      end
    end
  end
end
