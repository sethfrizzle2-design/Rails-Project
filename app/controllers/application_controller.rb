class ApplicationController < ActionController::Base
    include Authenticated
    include Pagy::Backend

    before_action :require_login

    private

        def require_login
            return if user_signed_in?

            redirect_to login_url
        end
end
