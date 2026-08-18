module Reports
    # Everything one report page needs: which responses count, how their
    # answers tally, and what the filter controls should offer.
    #
    # Responses are tied to a form by the form_name string rather than a
    # foreign key, and inputs denormalize question_id with no belongs_to, so
    # every query here starts from those two facts.
    class ResponseReport
        # Free-text questions can have as many distinct answers as there are
        # responses. The report still charts the top few, but the filter list
        # can afford to be longer before it stops being a usable control.
        CHOICE_LIMIT = 50

        attr_reader :form, :filter

        def initialize(form:, filter:)
            @form = form
            @filter = filter
        end

        def questions
            @questions ||= form.questions.order(:id).includes(:options)
                .select { |question| AnswerBreakdown::CHARTABLE_FORMATS.include?(question.format) }
        end

        def selected_questions
            @selected_questions ||= questions.select { |question| filter.question_selected?(question.id) }
        end

        def sections
            @sections ||= selected_questions.map do |question|
                Section.new(question: question, counts: counts[question.id] || {},
                    total_responses: total_responses)
            end
        end

        # The cohort the report describes, and the whole form for comparison.
        def total_responses
            @total_responses ||= responses.count
        end

        def overall_responses
            @overall_responses ||= base_responses.count
        end

        def filtered?
            filter.filtered?
        end

        # What the answer filter for a question should offer, in the order the
        # report reads that format, each with its unfiltered count.
        def answer_choices(question)
            @answer_choices ||= {}
            @answer_choices[question.id] ||=
                AnswerBreakdown.new(question, choice_counts[question.id] || {}, text_limit: CHOICE_LIMIT).rows
        end

        def generated_at
            @generated_at ||= Time.current
        end

        def filename
            "#{form.name.parameterize}-report-#{generated_at.strftime("%Y%m%d-%H%M")}.pdf"
        end

        private

            # One subquery per filtered question. Answers within a question are
            # an OR; separate questions AND together, so filtering colour=Red
            # and dogs=2 keeps only the responses that said both. Ids that are
            # not on this form are ignored rather than matching nothing.
            def responses
                @responses ||= filter.answers.slice(*questions.map(&:id))
                    .reduce(base_responses) do |scope, (question_id, answers)|
                        scope.where(id: Input.where(question_id: question_id, answer: answers).select(:response_id))
                    end
            end

            def base_responses
                @base_responses ||= begin
                    scope = Response.where(form_name: form.name)
                    scope = scope.where("responses.created_at >= ?", filter.from.beginning_of_day) if filter.from
                    scope = scope.where("responses.created_at <= ?", filter.to.end_of_day) if filter.to
                    scope
                end
            end

            # Counts inside the filtered cohort — the numbers the report shows.
            def counts
                @counts ||= grouped(Input.where(response_id: responses.select(:id)))
            end

            # Counts across the whole form, ignoring the answer filters. These
            # populate the filter checkboxes: built from the filtered cohort,
            # ticking "Red" would delete "Blue" and "Green" from the form and
            # leave no control to pick them back.
            def choice_counts
                @choice_counts ||= grouped(Input.where(response_id: base_responses.select(:id)))
            end

            # One grouped query for every question on the page rather than one
            # each, which scanned the inputs table once per question.
            def grouped(relation)
                return {} if questions.empty?

                rows = relation.where(question_id: questions.map(&:id)).group(:question_id, :answer).count

                rows.each_with_object({}) do |((question_id, answer), count), by_question|
                    (by_question[question_id] ||= {})[answer] = count
                end
            end
    end
end
