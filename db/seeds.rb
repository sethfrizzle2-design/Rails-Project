# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

    require 'faker'

    form = Form.find_by(name: "Better Test Form")

    300.times do
        response = Response.create!(form_name: form.name)

        form.questions.each do |q|
            
            case q.format
            when "Number"
                if q.words.include?("dogs")
                    answer = rand(1..4)
                elsif q.words.include?("jars")
                    answer = rand(1..10)
                end
            when "Text"
                if q.words.include?("food")
                    answer = Faker::Food.dish
                elsif q.words.include?("Mario")
                    answer = Faker::Games::SuperMario.character
                end

            when "Multiple Choice"
                answer = q.options.sample&.answer
            end

            response.inputs.create!(
                
                question_id: q.id,
                question_words: q.words,
                answer: answer
            )
        end
    end
