class ReportsController < ApplicationController
    def show
        @forms = Form.order(:name)
        @filter = Reports::Filter.from_params(params)
        @form = Form.find_by(id: @filter.form_id)
        @report = Reports::ResponseReport.new(form: @form, filter: @filter) if @form

        respond_to do |format|
            format.html
            format.pdf { send_report_pdf }
        end
    end

    private

        # The PDF is the same report through a different layout: one shared
        # partial, one renderer, no second copy of the numbers.
        def send_report_pdf
            return redirect_to report_path if @report.nil?

            html = render_to_string(template: "reports/pdf", layout: "pdf", formats: [:html])

            send_data Reports::PdfRenderer.new(html).to_pdf,
                filename: @report.filename, type: "application/pdf", disposition: "attachment"
        rescue Reports::PdfRenderer::Error => e
            # A missing browser is a deployment problem, not a bad request, and
            # the report is still perfectly readable on screen.
            logger.error("Report PDF failed: #{e.message}")
            redirect_to report_path(@filter.to_query_params), alert: "Could not build the PDF. The report is above."
        end
end
