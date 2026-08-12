class InputsController < ApplicationController
    def create
        @input = Input.new
    end
end
