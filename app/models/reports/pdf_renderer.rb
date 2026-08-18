require "tmpdir"

module Reports
    # Prints an HTML string with the browser the machine already has.
    #
    # The page is written to a temp file and opened over file://, so there is no
    # HTTP round-trip for headless Chrome to authenticate through — every
    # controller in this app is behind require_login — and no CDN for it to
    # reach, because the pdf layout inlines Highcharts and its own stylesheet.
    #
    # This is the only class that knows a PDF engine exists. Swapping engines
    # means rewriting this file and nothing else.
    class PdfRenderer
        class Error < StandardError; end

        BINARY = ENV.fetch("CHROME_BIN", "google-chrome")

        # --virtual-time-budget lets the page's own JavaScript run — the charts
        # draw on load — before Chrome captures it. The budget is virtual, so a
        # page that settles sooner is printed sooner.
        FLAGS = %w[
            --headless=new
            --disable-gpu
            --no-sandbox
            --no-pdf-header-footer
            --run-all-compositor-stages-before-draw
            --virtual-time-budget=10000
        ].freeze

        HIGHCHARTS_PATH = Rails.root.join("node_modules", "highcharts", "highcharts.js").freeze

        # Highcharts is already vendored for the browser page, so the PDF reads
        # that same copy off disk rather than the CDN it could not reach over
        # file:// anyway. Read once per process: it is 280 KB and does not
        # change while the app is up.
        def self.highcharts
            @highcharts ||= File.read(HIGHCHARTS_PATH)
        rescue Errno::ENOENT
            raise Error, "#{HIGHCHARTS_PATH} is missing. Run yarn install before generating a PDF."
        end

        def initialize(html)
            @html = html
        end

        def to_pdf
            Dir.mktmpdir("report") do |dir|
                page = File.join(dir, "report.html")
                pdf = File.join(dir, "report.pdf")

                File.write(page, @html)
                print_page(dir, page, pdf)

                File.binread(pdf)
            end
        end

        private

            # Chrome insists on a writable profile directory and will pick one
            # in the user's home otherwise, which a deployed app may not have.
            def print_page(dir, page, pdf)
                ok = system(BINARY, *FLAGS, "--user-data-dir=#{File.join(dir, "chrome")}",
                    "--print-to-pdf=#{pdf}", "file://#{page}",
                    out: File::NULL, err: File::NULL)

                return if ok && File.exist?(pdf)

                raise Error, "#{BINARY} could not print the report. Set CHROME_BIN if it is installed elsewhere."
            end
    end
end
