class BusesController < ApplicationController
    include Authenticated

    before_action :require_admin, only: [:new]

    def show
        @buses = Bus.all
        @locations = Bus.distinct.pluck(:location).compact_blank.uniq(&:downcase).sort_by(&:downcase)
        @choice = params[:something].presence
    end

    def new
        @bus = Bus.new
    end

    def create
        @bus = Bus.new(bus_params)
        begin
            redirect_to root_path, notice: "Successfully registered!" if @bus.save
        rescue StandardError
            redirect_to bus_make_path, alert: "Bus ID must be unique."
        end
    end

    private

        def bus_params
            params.require(:bus).permit(:bus_id, :location, :route_id)
        end

        def require_admin
            return if user_admin?

            redirect_to root_path, alert: "Admin needed."
        end
end
