module Reports
    # Turns one question's raw {answer => count} tally into the ordered rows a
    # chart or a table should show. Every rule about how a question format is
    # read lives here and nowhere else.
    class AnswerBreakdown
        # The three strings Question#format actually carries. A question saved
        # without a type picked keeps the select's placeholder and is not
        # reportable.
        CHARTABLE_FORMATS = ["Multiple Choice", "Number", "Text"].freeze

        # Text answers are free-form, so showing all of them is unreadable once
        # a question collects any variety. Show the most common ones only.
        TEXT_ANSWER_LIMIT = 15

        attr_reader :question, :counts, :text_limit

        def initialize(question, counts, text_limit: TEXT_ANSWER_LIMIT)
            @question = question
            @counts = counts || {}
            @text_limit = text_limit
        end

        def format
            question.format
        end

        # [[answer, count], ...] in the order this format should be read.
        def rows
            @rows ||= ordered_rows
        end

        # True when the format dropped answers to stay readable, which the title
        # then says out loud rather than quietly under-reporting.
        def truncated?
            counts.size > rows.size
        end

        def title
            return question.words unless truncated?

            "#{question.words} (top #{rows.size} of #{counts.size})"
        end

        # The hash ChartsHelper#question_chart_tag expects.
        def chart
            { id: "chart_#{question.id}", format: format, title: title, data: rows }
        end

        # Min, max, mean and median for a Number question, weighted straight out
        # of the tally so there is no second pass over the inputs table. Answers
        # that are not numbers are excluded and counted, because the column is a
        # string and nothing stops someone typing "a few".
        def numeric_summary
            return nil unless format == "Number"

            values = counts.flat_map { |answer, count| Array.new(count, numeric(answer)) }
            numbers = values.compact.sort
            return nil if numbers.empty?

            {
                count: numbers.size,
                skipped: values.size - numbers.size,
                min: numbers.first,
                max: numbers.last,
                mean: numbers.sum / numbers.size,
                median: median(numbers)
            }
        end

        private

            def ordered_rows
                case format
                when "Multiple Choice"
                    multiple_choice_rows
                when "Number"
                    counts.sort_by { |answer, _count| numeric(answer) || Float::INFINITY }
                when "Text"
                    counts.sort_by { |_answer, count| -count }.first(text_limit)
                else
                    counts.to_a
                end
            end

            # The question's own options give the canonical order and keep the
            # options nobody picked. An answer that is no longer one of the
            # options is appended rather than silently dropped.
            def multiple_choice_rows
                listed = question.options.map(&:answer)
                unlisted = counts.keys - listed

                (listed + unlisted).map { |answer| [answer, counts[answer] || 0] }
            end

            def numeric(answer)
                Float(answer, exception: false)
            end

            def median(numbers)
                middle = numbers.size / 2

                return numbers[middle] if numbers.size.odd?

                (numbers[middle - 1] + numbers[middle]) / 2
            end
    end
end
