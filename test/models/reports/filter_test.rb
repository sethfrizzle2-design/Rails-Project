require "test_helper"

module Reports
    class FilterTest < ActiveSupport::TestCase
        def filter(params = {})
            Reports::Filter.from_params(ActionController::Parameters.new(params))
        end

        test "no question_ids key means every question, not none" do
            assert filter.all_questions?
            assert filter.question_selected?(101)
        end

        test "a list with only the form's blank entry means the user unchecked everything" do
            chosen = filter(question_ids: [""])

            assert_not chosen.all_questions?
            assert_not chosen.question_selected?(101)
        end

        test "reads question ids as numbers" do
            assert filter(question_ids: ["", "101"]).question_selected?(101)
        end

        test "reads answers as a list per question and drops the blank entry" do
            chosen = filter(answers: { "101" => ["", "Red", "Blue"] })

            assert_equal %w[Red Blue], chosen.answers_for(101)
            assert chosen.answer_selected?(101, "Red")
            assert_not chosen.answer_selected?(101, "Green")
        end

        test "a question with nothing left checked is dropped rather than matching nothing" do
            chosen = filter(answers: { "101" => [""] })

            assert_empty chosen.answers
            assert_not chosen.filtered?
        end

        test "ignores a date it cannot read instead of erroring" do
            assert_nil filter(from: "not a date").from
            assert_nil filter(from: "").from
            assert_equal Date.new(2026, 1, 3), filter(from: "2026-01-03").from
        end

        test "round-trips back into the params it was parsed from" do
            params = { form_id: "7", question_ids: ["", "101", "102"],
                       answers: { "101" => ["", "Red"] }, from: "2026-01-03", to: "2026-01-05" }

            assert_equal({
                form_id: "7",
                question_ids: ["", "101", "102"],
                answers: { "101" => ["Red"] },
                from: "2026-01-03",
                to: "2026-01-05"
            }, filter(params).to_query_params)
        end

        test "a round trip keeps the difference between all questions and none" do
            assert_not_includes filter(form_id: "7").to_query_params, :question_ids
            assert_equal [""], filter(form_id: "7", question_ids: [""]).to_query_params[:question_ids]
        end

        test "a round trip of an unfiltered report carries only the form" do
            assert_equal({ form_id: "7" }, filter(form_id: "7").to_query_params)
        end
    end
end
