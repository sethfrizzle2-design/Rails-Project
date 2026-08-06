class ApplicationController < ActionController::Base
    include Authenticated

    before_action :require_login


    private
        def require_login
            unless user_signed_in?
                redirect_to login_url
            end
        end
end
