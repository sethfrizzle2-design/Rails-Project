require "test_helper"

# The Report Form cohort these tests read against:
#
#   response | colour | dogs | note
#   ---------+--------+------+-------
#   rf_1     | Red    |  2   | Great
#   rf_2     | Red    | 10   | Great
#   rf_3     | Blue   |  2   | Fine
#   rf_4     | Blue   |  2   | (skipped)
#   rf_5     | Red    |  9   | Great
#
# Green is an option nobody picked, and a sixth response sits on the Survey
# form carrying a Report Form question id.
module Reports
    class ResponseReportTest < ActiveSupport::TestCase
        def report(params = {})
            form = forms(:report_form)

            Reports::ResponseReport.new(form: form, filter: Reports::Filter.from_params(params))
        end

        def section_for(report, question)
            report.sections.find { |section| section.question == question }
        end

        def rows_for(report, question)
            section_for(report, question).rows.map { |row| [row.answer, row.count] }
        end

        test "reports every question whose format has a defined ordering" do
            assert_equal [questions(:rf_color), questions(:rf_dogs), questions(:rf_note)], report.questions
        end

        test "leaves out a question saved without a type picked" do
            report = Reports::ResponseReport.new(form: forms(:survey), filter: Reports::Filter.from_params({}))

            assert_not_includes report.questions, questions(:untyped)
        end

        test "counts only the responses belonging to this form" do
            assert_equal 5, report.total_responses
            assert_equal 5, report.overall_responses
        end

        test "an answer on another form never reaches this report" do
            # The Survey response answers the colour question with Green, which is
            # the one option the Report Form cohort never picks.
            assert_equal 0, rows_for(report, questions(:rf_color)).to_h.fetch("Green")
        end

        test "no question_ids at all is the first look, so every question is on" do
            assert_equal report.questions, report.selected_questions
        end

        test "a present but empty question_ids means the user unchecked everything" do
            assert_empty report(question_ids: [""]).sections
        end

        test "only the checked questions get a section" do
            sections = report(question_ids: ["", "101"]).sections

            assert_equal [questions(:rf_color)], sections.map(&:question)
        end

        test "multiple choice keeps its option order and keeps options nobody picked" do
            assert_equal [["Red", 3], ["Blue", 2], ["Green", 0]], rows_for(report, questions(:rf_color))
        end

        test "number answers sort numerically rather than as strings" do
            assert_equal [["2", 3], ["9", 1], ["10", 1]], rows_for(report, questions(:rf_dogs))
        end

        test "text answers sort by how common they are" do
            assert_equal [["Great", 3], ["Fine", 1]], rows_for(report, questions(:rf_note))
        end

        test "percentages are a share of the people who answered, not of the cohort" do
            section = section_for(report, questions(:rf_note))

            # One of the five skipped the question, so Great is 3 of 4, not 3 of 5.
            assert_equal 5, section.total_responses
            assert_equal 4, section.answered_count
            assert_equal 1, section.skipped_count
            assert_in_delta 75.0, section.rows.first.percent
        end

        test "an answer filter narrows which responses count, not just which bars draw" do
            filtered = report(answers: { "101" => ["", "Red"] })

            assert_equal 3, filtered.total_responses
            assert_equal 5, filtered.overall_responses
            assert filtered.filtered?
        end

        test "answers within one question are an or" do
            filtered = report(answers: { "101" => ["", "Red", "Blue"] })

            assert_equal 5, filtered.total_responses
        end

        test "answers across questions are an and" do
            # Red and 2 dogs is rf_1 alone.
            filtered = report(answers: { "101" => ["", "Red"], "102" => ["", "2"] })

            assert_equal 1, filtered.total_responses
            assert_equal [["Great", 1]], rows_for(filtered, questions(:rf_note))
        end

        test "a filter narrows the other questions too" do
            filtered = report(answers: { "101" => ["", "Red"] })

            assert_equal [["2", 1], ["9", 1], ["10", 1]], rows_for(filtered, questions(:rf_dogs))
        end

        test "an answer filter for a question on another form is ignored" do
            filtered = report(answers: { questions(:color).id.to_s => ["", "Red"] })

            assert_equal 5, filtered.total_responses
        end

        test "a filter that matches nothing reports an empty section rather than blowing up" do
            filtered = report(answers: { "101" => ["", "Green"] })

            assert_equal 0, filtered.total_responses
            assert_not section_for(filtered, questions(:rf_note)).answered?
            assert_equal 0.0, section_for(filtered, questions(:rf_color)).rows.first.percent
        end

        test "dates narrow the cohort at both ends" do
            assert_equal 3, report(from: "2026-01-03").total_responses
            assert_equal 2, report(to: "2026-01-02").total_responses
            assert_equal 2, report(from: "2026-01-02", to: "2026-01-03").total_responses
        end

        test "a date filter includes the whole of its last day" do
            # rf_5 is stamped 09:00, so an exclusive upper bound would drop it.
            assert_equal 5, report(to: "2026-01-05").total_responses
        end

        test "answer choices come from the whole form so a filter cannot hide itself" do
            filtered = report(answers: { "101" => ["", "Red"] })
            choices = filtered.answer_choices(questions(:rf_color))

            assert_equal [["Red", 3], ["Blue", 2], ["Green", 0]], choices
        end

        test "number questions summarise their answers" do
            summary = section_for(report, questions(:rf_dogs)).numeric_summary

            assert_equal 5, summary[:count]
            assert_equal 0, summary[:skipped]
            assert_in_delta 2.0, summary[:min]
            assert_in_delta 10.0, summary[:max]
            assert_in_delta 5.0, summary[:mean]
            assert_in_delta 2.0, summary[:median]
        end

        test "other formats have no numeric summary" do
            assert_nil section_for(report, questions(:rf_note)).numeric_summary
            assert_nil section_for(report, questions(:rf_color)).numeric_summary
        end

        test "sections hand ChartsHelper the hash it expects" do
            chart = section_for(report, questions(:rf_color)).chart

            assert_equal "chart_101", chart[:id]
            assert_equal "Multiple Choice", chart[:format]
            assert_equal "Which colour?", chart[:title]
            assert_equal [["Red", 3], ["Blue", 2], ["Green", 0]], chart[:data]
        end

        test "the filename names the form and when the report was taken" do
            assert_match(/\Areport-form-report-\d{8}-\d{4}\.pdf\z/, report.filename)
        end
    end
end
