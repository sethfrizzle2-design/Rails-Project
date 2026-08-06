class QuestionsController < ApplicationController


    def create
        @question = Question.new

    end

    def remove
        @target = params[:target]
    end
end