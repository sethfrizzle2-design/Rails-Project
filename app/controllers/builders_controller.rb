class BuildersController < ApplicationController

    def show
        @form
        @question = Question.all
        @option = Option.all
        @choice = params[:choose]
    end

end
