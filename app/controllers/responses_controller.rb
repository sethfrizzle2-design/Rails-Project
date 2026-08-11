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


        @pie_data = ((Input.where(question_words: "Do you like pie?").group(:answer).count).to_a)

        @mario_data = ((Input.where(question_words: "Who is your favorite Super Mario character?").group(:answer).count).to_a)

        @color_data = ((Input.where(question_words: "What is your favorite color?").group(:answer).count).to_a)

        @food_data = ((Input.where(question_words: "What is your favorite food?").group(:answer).count).to_a)

        number_order = %w[1 2 3 4 5 6 7 8 9 10]

        @jar_data = (number_order.index_with {|number| Input.where(question_words: "How many jars do you own?").group(:answer).count[number] || 0 }).to_a

        @dog_data = ((Input.where(question_words: "How many dogs do you have?").group(:answer).count).to_a)

        day_order = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

        @week_data = (day_order.index_with { |day| Input.where(question_words: "What is your favorite day of the week?").group(:answer).count[day] || 0 }).to_a
        
        
        
        
        
        

                    
            
    
        

    end

    private

        def collect



        end

        def response_params
            params.require(:response).permit(:form_name, inputs_attributes: [:answer, :question_id, :question_words, :_destroy])
        end

end
