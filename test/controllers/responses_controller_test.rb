require "test_helper"

class ResponsesControllerTest < ActionDispatch::IntegrationTest
    setup do
        post login_path, params: { user: { email: users(:tester).email, password: "secret123" } }
    end


    test "chart renders an empty state until a form is picked" do
        get response_chart_path

        assert_response :success
        assert_select "[data-highchart]", 0
        assert_select "turbo-frame#Charts", text: /Select a form/
    end

    test "chart draws every chartable question when a form is first picked" do
        get response_chart_path, params: { form_id: forms(:survey).id }

        assert_response :success

        # Five questions on the form, but the untyped one is not chartable.
        assert_select "[data-highchart]", 3
        assert_select "input[type=checkbox][name='question_ids[]']", 4
        assert_select "input[type=checkbox][checked]", 4
        assert_select "input[type=checkbox][value=?]", questions(:untyped).id.to_s, 0
    end

    test "chart draws only the checked questions" do
        get response_chart_path,
            params: { form_id: forms(:survey).id, question_ids: ["", questions(:color).id] }

        assert_response :success
        assert_select "[data-highchart]", 1
        assert_select "#chart_#{questions(:color).id}"
    end

    test "chart draws nothing but keeps the filter when everything is unchecked" do
        get response_chart_path, params: { form_id: forms(:survey).id, question_ids: [""] }

        assert_response :success
        assert_select "[data-highchart]", 0
        assert_select "input[type=checkbox][name='question_ids[]']", 4
        assert_select "turbo-frame#Charts", text: /No charts selected/
    end

    test "chart reports a form with no chartable questions" do
        get response_chart_path, params: { form_id: forms(:blank_form).id }

        assert_response :success
        assert_select "[data-highchart]", 0
        assert_select "turbo-frame#Charts", text: /no chartable questions/
    end

    test "chart notes a question nobody has answered instead of drawing an empty chart" do
        get response_chart_path, params: { form_id: forms(:survey).id }

        assert_response :success
        assert_select "#chart_#{questions(:notes).id}", 0
        assert_select "turbo-frame#Charts", text: /no responses yet/
    end

    test "multiple choice keeps its option order and shows options nobody picked" do
        get response_chart_path,
            params: { form_id: forms(:survey).id, question_ids: ["", questions(:color).id] }

        assert_equal [["Red", 2], ["Blue", 1], ["Green", 0]], chart_data_for(questions(:color))
    end

    test "number answers sort numerically rather than as strings" do
        get response_chart_path,
            params: { form_id: forms(:survey).id, question_ids: ["", questions(:dogs).id] }

        assert_equal [["2", 3], ["9", 2], ["10", 1]], chart_data_for(questions(:dogs))
    end

    test "text answers are capped at the most common fifteen and the title says so" do
        get response_chart_path,
            params: { form_id: forms(:survey).id, question_ids: ["", questions(:food).id] }

        data = chart_data_for(questions(:food))

        assert_equal 15, data.size
        assert_equal ["Food 01", 20], data.first
        assert_equal ["Food 15", 6], data.last
        assert_select "#chart_#{questions(:food).id}" do |chart|
            assert_equal "What is your favorite food? (top 15 of 20)",
                JSON.parse(chart.first["data-highchart"])["title"]["text"]
        end
    end

    test "multiple choice draws a pie and other formats draw columns" do
        get response_chart_path, params: { form_id: forms(:survey).id }

        assert_equal "pie", chart_config_for(questions(:color))["chart"]["type"]
        assert_equal "column", chart_config_for(questions(:dogs))["chart"]["type"]
        assert_equal "column", chart_config_for(questions(:food))["chart"]["type"]
    end

    private

        def chart_config_for(question)
            container = css_select("#chart_#{question.id}").first

            assert_not_nil container, "expected a chart for #{question.words}"

            JSON.parse(container["data-highchart"])
        end

        # Column and bar charts carry one series per answer; pies carry a single
        # series of [answer, count] slices.
        def chart_data_for(question)
            series = chart_config_for(question)["series"]

            if series.size == 1 && series.first["data"].first.is_a?(Array)
                series.first["data"]
            else
                series.map { |entry| [entry["name"], entry["data"].first] }
            end
        end
end
