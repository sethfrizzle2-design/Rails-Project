require "test_helper"

# Object#stub, used to keep the PDF tests from launching a browser.
require "minitest/mock"

class ReportsControllerTest < ActionDispatch::IntegrationTest
    setup do
        post login_path, params: { user: { email: users(:tester).email, password: "secret123" } }
    end

    test "reports are behind the login" do
        delete logout_path
        get report_path

        assert_redirected_to login_url
    end

    test "renders an empty state until a form is picked" do
        get report_path

        assert_response :success
        assert_select "[data-highchart]", 0
        assert_select "turbo-frame#Report", text: /Select a form/
    end

    test "reports every reportable question when a form is first picked" do
        get report_path, params: { form_id: forms(:report_form).id }

        assert_response :success
        assert_select "[data-highchart]", 3
        assert_select "input[type=checkbox][name='question_ids[]'][checked]", 3
    end

    test "reports only the checked questions" do
        get report_path, params: { form_id: forms(:report_form).id, question_ids: ["", "101"] }

        assert_response :success
        assert_select "[data-highchart]", 1
        assert_select "#chart_101"
    end

    test "keeps the filters on screen when every question is unchecked" do
        get report_path, params: { form_id: forms(:report_form).id, question_ids: [""] }

        assert_response :success
        assert_select "[data-highchart]", 0
        assert_select "input[type=checkbox][name='question_ids[]']", 3
        assert_select "turbo-frame#Report", text: /No questions selected/
    end

    test "reports a form with nothing reportable on it" do
        get report_path, params: { form_id: forms(:blank_form).id }

        assert_response :success
        assert_select "turbo-frame#Report", text: /no questions that can be reported on/
    end

    test "shows counts and shares in the table" do
        get report_path, params: { form_id: forms(:report_form).id, question_ids: ["", "101"] }

        # Red is 3 of the 5 who answered.
        assert_select "td", text: "Red"
        assert_select "td", text: "60.0%"
    end

    test "an answer filter narrows the whole report" do
        get report_path, params: { form_id: forms(:report_form).id, answers: { "101" => ["", "Red"] } }

        assert_response :success
        assert_select "turbo-frame#Report", text: /3 responses of 5/
        assert_select "input[type=checkbox][name='answers[101][]'][value=Red][checked]"
    end

    test "the filter still offers answers the current filter excludes" do
        get report_path, params: { form_id: forms(:report_form).id, answers: { "101" => ["", "Red"] } }

        # Built from the whole form, so unpicking Blue never removes the box
        # you would use to pick it back.
        assert_select "input[type=checkbox][name='answers[101][]'][value=Blue]"
        assert_select "input[type=checkbox][name='answers[101][]'][value=Green]"
    end

    test "notes a question nobody has answered instead of drawing an empty chart" do
        get report_path, params: { form_id: forms(:report_form).id, answers: { "101" => ["", "Green"] } }

        assert_response :success
        assert_select "[data-highchart]", 0
        assert_select "turbo-frame#Report", text: /No responses yet/
    end

    test "the download link carries the filters that are on screen" do
        get report_path,
            params: { form_id: forms(:report_form).id, question_ids: ["", "101"],
                      answers: { "101" => ["", "Red"] } }

        link = css_select("a[href$='.pdf'], a[href*='.pdf?']").first
        assert_not_nil link, "expected a PDF download link"

        query = Rack::Utils.parse_nested_query(URI.parse(link["href"]).query)

        assert_equal forms(:report_form).id.to_s, query["form_id"]
        assert_equal ["", "101"], query["question_ids"]
        assert_equal ["Red"], query["answers"]["101"]
    end

    # Launching a browser in the unit suite is slow and depends on the machine
    # having one, so these check everything up to the subprocess: that the same
    # report reaches the renderer, and how it is sent back.
    test "the pdf is the same report through the pdf layout" do
        printed = nil

        with_stubbed_renderer(->(html) { printed = html }) do
            get report_path(format: :pdf, form_id: forms(:report_form).id, question_ids: ["", "101"])
        end

        assert_response :success
        assert_equal "application/pdf", response.media_type

        # Rendered by reports/_section, exactly as the browser page renders it.
        assert_match(/Which colour\?/, printed)
        assert_match(/60\.0%/, printed)
        assert_select_in printed, "[data-highchart]", 1
    end

    test "the pdf inlines Highcharts rather than linking a CDN it cannot reach" do
        printed = nil

        with_stubbed_renderer(->(html) { printed = html }) do
            get report_path(format: :pdf, form_id: forms(:report_form).id)
        end

        assert_no_match(/<script src=/, printed)
        assert_match(/Highcharts/, printed)
    end

    test "the pdf carries the same filters as the page it was linked from" do
        printed = nil

        with_stubbed_renderer(->(html) { printed = html }) do
            get report_path(format: :pdf, form_id: forms(:report_form).id,
                answers: { "101" => ["", "Red"] })
        end

        assert_match(/3 responses/, printed)
    end

    test "the pdf is offered as a download named after the form" do
        with_stubbed_renderer(->(_html) {}) do
            get report_path(format: :pdf, form_id: forms(:report_form).id)
        end

        assert_match(/attachment/, response.headers["Content-Disposition"])
        assert_match(/report-form-report-\d{8}-\d{4}\.pdf/, response.headers["Content-Disposition"])
    end

    test "asking for a pdf without a form goes back to the picker" do
        get report_path(format: :pdf)

        assert_redirected_to report_path
    end

    test "a machine with no browser sends the user back to the readable report" do
        with_stubbed_renderer(->(_html) { raise Reports::PdfRenderer::Error, "no chrome" }) do
            get report_path(format: :pdf, form_id: forms(:report_form).id)
        end

        assert_redirected_to report_path(form_id: forms(:report_form).id.to_s)
        assert_match(/Could not build the PDF/, flash[:alert])
    end

    # The whole pipeline, browser and all. Skipped rather than failed on a
    # machine without Chrome, because that is a deployment fact and not a
    # broken report — but where a browser exists this is the only test that
    # proves the layout actually prints.
    test "headless chrome prints the report for real" do
        binary = Reports::PdfRenderer::BINARY
        skip "#{binary} is not on this machine" unless system("which", binary, out: File::NULL, err: File::NULL)

        get report_path(format: :pdf, form_id: forms(:report_form).id)

        assert_response :success
        assert_equal "application/pdf", response.media_type
        assert response.body.start_with?("%PDF"), "expected a PDF, got #{response.body[0, 40].inspect}"
    end

    test "the filter form always submits a blank entry for each list" do
        get report_path, params: { form_id: forms(:report_form).id }

        assert_select "input[type=hidden][name='question_ids[]'][value='']"
        assert_select "input[type=hidden][name='answers[101][]'][value='']"
    end

    private

        FakePdf = Struct.new(:to_pdf)

        # Swaps the browser subprocess for a block that sees the HTML it would
        # have printed, which is the part worth asserting on.
        def with_stubbed_renderer(handler, &block)
            fake = ->(html) { FakePdf.new(handler.call(html) || "%PDF-1.4") }

            Reports::PdfRenderer.stub(:new, fake, &block)
        end

        def assert_select_in(html, selector, count)
            assert_equal count, Nokogiri::HTML(html).css(selector).size,
                "expected #{count} #{selector} in the printed page"
        end
end
