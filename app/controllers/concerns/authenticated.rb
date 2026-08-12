module Authenticated
    extend ActiveSupport::Concern

    included do
        before_action :current_user
        helper_method :current_user
        helper_method :user_signed_in?
    end

    def current_user
        return unless session[:current_user_id]

        current_user ||= User.find_by(id: session[:current_user_id])
    end

    def user_signed_in?
        current_user.present?
    end

    def user_admin?
        current_user.admin?
    end
end
