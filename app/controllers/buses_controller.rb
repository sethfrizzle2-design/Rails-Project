class BusesController < ApplicationController
    include Authenticated

    before_action :require_admin, only: [:new]


    def show
        @buses = Bus.all
        @choice = params[:something] 
    end

    def new
        @bus = Bus.new
    end

    def create
        @bus = Bus.new(bus_params)
        begin 
            if @bus.save
                redirect_to root_path, notice: 'Successfully registered!'
            end
        rescue
            redirect_to bus_make_path, alert: "Bus ID must be unique."
        end
    end

    private

    def bus_params
        params.require(:bus).permit(:bus_id, :location, :route_id)
    end

    def require_admin
        unless user_admin?
            redirect_to root_path, alert: "Admin needed."
        end
    end

end
