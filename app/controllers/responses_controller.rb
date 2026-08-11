class ResponsesController < ApplicationController

    

    def new
        @response = Response.new
        @response.inputs.build
        @form
        @question = Question.all
        @option = Option.all
        @choice = params[:choose]
    end


    def create
        
        @response = Response.new(response_params)

        if @response.save
            redirect_to root_path, notice: 'Response Submitted'
        end
    end

    def show

        
        @form = Form.all
        @pickedform
        @response
        @input = Input.all
        @reschoice = params[:choose]
        @forchoice = params[:choose2]
        

    end

    def chart

        @response = Response.all

    end

    private
        def response_params
            params.require(:response).permit(:form_name, inputs_attributes: [:answer, :question_id, :question_words, :_destroy])
        end

end
