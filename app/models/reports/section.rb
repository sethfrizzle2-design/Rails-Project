module Reports
    # One question's slice of a report: its ordered answers with counts and
    # shares, plus whatever summary the format supports.
    class Section
        # A plain class rather than a Struct, because a Struct member named
        # count would quietly override Struct#count.
        class Row
            attr_reader :answer, :count, :percent

            def initialize(answer, count, percent)
                @answer = answer
                @count = count
                @percent = percent
            end
        end

        attr_reader :question, :breakdown, :total_responses

        def initialize(question:, counts:, total_responses:)
            @question = question
            @breakdown = AnswerBreakdown.new(question, counts)
            @total_responses = total_responses
        end

        delegate :format, :title, :truncated?, :chart, :numeric_summary, to: :breakdown

        def rows
            @rows ||= breakdown.rows.map { |answer, count| Row.new(answer, count, percent_of(count)) }
        end

        # A response carries one input per question it answered, so counting
        # inputs counts the people who answered.
        def answered_count
            @answered_count ||= breakdown.counts.values.sum
        end

        # Never negative: a response that somehow stored two inputs for one
        # question would otherwise report a nonsense "-1 skipped".
        def skipped_count
            [total_responses - answered_count, 0].max
        end

        def answered?
            answered_count.positive?
        end

        private

            # A share of the people who answered this question, not of the whole
            # cohort. A question a third of them skipped would otherwise read as
            # though every one of its answers were unpopular.
            def percent_of(count)
                return 0.0 unless answered?

                (count * 100.0) / answered_count
            end
    end
end
