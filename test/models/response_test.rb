require "test_helper"

class ResponseTest < ActiveSupport::TestCase
    
    test "saves correctly" do

        response = Response.new(form_name: "Test Form", inputs_attributes: [{answer: "A", question_id: 88, question_words: "Multiple Test"}])

        assert_difference("Input.count", 1) do
            response.save
        end
    end
end
