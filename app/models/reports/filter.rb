module Reports
    # The report's query params as an object. It parses what the browser sent
    # and hands the same thing back through #to_query_params, so the PDF link
    # can carry the exact report that is on screen.
    class Filter
        attr_reader :form_id, :question_ids, :answers, :from, :to

        def self.from_params(params)
            new(form_id: params[:form_id], question_ids: params[:question_ids],
                answers: params[:answers], from: params[:from], to: params[:to])
        end

        def initialize(form_id: nil, question_ids: nil, answers: nil, from: nil, to: nil)
            @form_id = form_id.presence
            @question_ids = parse_ids(question_ids)
            @answers = parse_answers(answers)
            @from = parse_date(from)
            @to = parse_date(to)
        end

        # No question_ids key at all is the first look at a form, so every
        # question is on. The filter form always submits a blank entry, so the
        # key present but empty means the user unchecked everything.
        def all_questions?
            question_ids.nil?
        end

        def question_selected?(question_id)
            all_questions? || question_ids.include?(question_id)
        end

        def answers_for(question_id)
            answers[question_id] || []
        end

        def answer_selected?(question_id, answer)
            answers_for(question_id).include?(answer)
        end

        def any_answers?
            answers.any?
        end

        def dates?
            !from.nil? || !to.nil?
        end

        def filtered?
            any_answers? || dates?
        end

        # Rebuilds the params this filter was parsed from, so a link built with
        # them renders the identical report in another format. The blank entry
        # goes back into question_ids for the same reason the form emits one.
        def to_query_params
            params = { form_id: form_id }
            params[:question_ids] = [""] + question_ids.map(&:to_s) unless all_questions?
            params[:answers] = answers.transform_keys(&:to_s) if any_answers?
            params[:from] = from.to_s if from
            params[:to] = to.to_s if to
            params.compact
        end

        private

            def parse_ids(ids)
                return nil if ids.nil?

                Array(ids).reject(&:blank?).map(&:to_i)
            end

            # Comes in as answers[<question id>][] and, like question_ids, each
            # list carries a blank entry so an empty list still reaches us.
            # A question with nothing left is dropped rather than kept as an
            # impossible "matches none" condition.
            #
            # The keys are question ids the user picked, so they cannot be named
            # in a permit list; permit! is safe here because nothing in the hash
            # is ever assigned to a record, only compared as a string.
            def parse_answers(answers)
                
                return {} if answers.blank?

                answers = answers.permit!.to_h if answers.respond_to?(:permit!)

                answers.to_h.each_with_object({}) do |(question_id, list), parsed|
                    chosen = Array(list).reject(&:blank?)
                    parsed[question_id.to_i] = chosen if chosen.any?
                end
            end

            def parse_date(value)
                return nil if value.blank?

                Date.parse(value.to_s)
            rescue ArgumentError
                nil
            end
    end
end
