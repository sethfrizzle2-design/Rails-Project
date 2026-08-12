class ResponsesController < ApplicationController
    CHARTABLE_FORMATS = ["Multiple Choice", "Number", "Text"].freeze

    # Text answers are free-form, so charting all of them is unreadable once a
    # question collects any variety. Show the most common ones only.
    TEXT_ANSWER_LIMIT = 15

    def new
        @response = Response.new
        @response.inputs.build
        @form
        @question = Question.all
        @option = Option.all
        @choice = params[:choose]
    end

    def create
        @response = Response.new(response_params)

        return unless @response.save

        redirect_to root_path, notice: "Response Submitted"
    end

    def show
        @form = Form.all
        @pickedform
        @response
        @input = Input.all
        @reschoice = params[:choose]
        @forchoice = params[:choose2]
    end

    def chart
        @forms = Form.order(:name)
        @form = Form.find_by(id: params[:form_id])
        @questions = chartable_questions(@form)
        @selected_ids = selected_question_ids(@questions)
        @charts = build_charts(@questions.select { |question| @selected_ids.include?(question.id) })
    end

    private

        def collect; end

        def chartable_questions(form)
            return [] if form.nil?

            form.questions.order(:id).includes(:options)
                .select { |question| CHARTABLE_FORMATS.include?(question.format) }
        end

        # No question_ids key at all means this is the first look at the form, so
        # every chart is on. The filter form always submits a blank entry, so the
        # key present but empty means the user unchecked everything.
        def selected_question_ids(questions)
            return questions.map(&:id) if params[:question_ids].nil?

            Array(params[:question_ids]).reject(&:blank?).map(&:to_i)
        end

        # One grouped query for every selected question rather than one query
        # each, which scanned the inputs table once per question.
        def answer_counts(questions)
            return {} if questions.empty?

            rows = Input.where(question_id: questions.map(&:id)).group(:question_id, :answer).count

            rows.each_with_object({}) do |((question_id, answer), count), grouped|
                (grouped[question_id] ||= {})[answer] = count
            end
        end

        def build_charts(questions)
            counts = answer_counts(questions)

            questions.map do |question|
                for_question = counts[question.id] || {}
                data = chart_data(question, for_question)

                {
                    id: "chart_#{question.id}",
                    format: question.format,
                    title: chart_title(question, for_question.size, data.size),
                    data: data
                }
            end
        end

        def chart_data(question, counts)
            case question.format
            when "Multiple Choice"
                multiple_choice_data(question, counts)
            when "Number"
                counts.sort_by { |answer, _count| Float(answer, exception: false) || Float::INFINITY }
            when "Text"
                counts.sort_by { |_answer, count| -count }.first(TEXT_ANSWER_LIMIT)
            else
                counts.to_a
            end
        end

        # The question's own options give the canonical order and keep options
        # nobody picked on the chart. An answer that is no longer one of the
        # options is appended rather than silently dropped.
        def multiple_choice_data(question, counts)
            listed = question.options.map(&:answer)
            unlisted = counts.keys - listed

            (listed + unlisted).map { |answer| [answer, counts[answer] || 0] }
        end

        def chart_title(question, total_answers, shown_answers)
            return question.words if total_answers <= shown_answers

            "#{question.words} (top #{shown_answers} of #{total_answers})"
        end

        def response_params
            params.require(:response).permit(:form_name,
                inputs_attributes: %i[answer question_id question_words _destroy])
        end
end
