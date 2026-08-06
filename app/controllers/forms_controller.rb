class FormsController < ApplicationController

    def new
        @form = Form.new
        @form.questions.build
    end

    def create
        
        @form = Form.new(form_params)

        if @form.save
            redirect_to root_path, notice: 'Form Created!'
        else
            render :new
        end
    end

    private
        def form_params
            params.require(:form).permit(:name, questions_attributes: [ :words, :format, :_destroy, options_attributes: [:answer]])
        end
end