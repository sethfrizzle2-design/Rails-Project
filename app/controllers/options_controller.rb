class OptionsController < ApplicationController

    def create
        @parent_name = params[:parent_name]
        @target = params[:target]
        
    end

    def remove
        @target = params[:target]
    end

end
