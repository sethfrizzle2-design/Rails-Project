module ReportsHelper
    # The pdf layout inlines the charting library rather than linking it.
    def inline_highcharts
        Reports::PdfRenderer.highcharts
    end

    # One decimal place is as much precision as a count of responses justifies.
    def report_percent(percent)
        "#{number_with_precision(percent, precision: 1)}%"
    end

    # Whole numbers stay whole, so a summary reads "2 dogs" and not "2.00".
    def report_summary_number(value)
        number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
    end

    # The filters in force, in words, for the report header and the PDF's cover
    # line. Read off the form's own questions rather than the raw params, so a
    # stale question id in a pasted URL cannot show up as a filter nobody set.
    def applied_filters(report)
        described = report.questions.map { |question| describe_answer_filter(report.filter, question) }
        described += describe_date_filter(report.filter)
        described.compact
    end

    private

        def describe_answer_filter(filter, question)
            answers = filter.answers_for(question.id)
            return nil if answers.empty?

            "#{question.words} #{answers.to_sentence(two_words_connector: " or ", last_word_connector: ", or ")}"
        end

        def describe_date_filter(filter)
            [
                ("On or after #{l(filter.from, format: :long)}" if filter.from),
                ("On or before #{l(filter.to, format: :long)}" if filter.to)
            ]
        end
end
