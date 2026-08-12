module ChartsHelper
    CHART_STYLE = "width:100%; height:400px;".freeze

    RESPONSE_COUNT_AXIS = { title: { text: "Number of Responses" } }.freeze

    # Column charts get one series per answer, so every answer is its own
    # coloured column inside a single blank category.
    def column_chart_tag(id, title:, data:, y_axis: {}, group_padding: 0.05)
        chart_tag(id, {
            chart: { type: "column" },
            plotOptions: { column: { pointPadding: 0.1, groupPadding: group_padding } },
            title: { text: title },
            xAxis: { categories: [" "] },
            yAxis: RESPONSE_COUNT_AXIS.merge(y_axis),
            series: series_per_answer(data)
        })
    end

    # Same series shape as a column chart, drawn sideways.
    def bar_chart_tag(id, title:, data:, y_axis: {})
        chart_tag(id, {
            chart: { type: "bar" },
            title: { text: title },
            xAxis: { categories: [" "] },
            yAxis: RESPONSE_COUNT_AXIS.merge(y_axis),
            series: series_per_answer(data)
        })
    end

    # Pie charts take one series whose slices are [answer, count] pairs.
    def pie_chart_tag(id, title:, data:, colors: nil, percentage_format: "{point.percentage:.1f}%")
        options = {
            chart: { type: "pie" },
            title: { text: title },
            series: [{
                name: "Requests",
                # We can show multiple data labels per point
                dataLabels: [
                    { format: "{point.name}" },
                    {
                        format: percentage_format,
                        distance: -30,
                        style: { fontSize: "0.9em", textOutline: "none" }
                    }
                ],
                data: data.map { |answer, count| [answer, count] }
            }]
        }

        options[:colors] = colors if colors

        chart_tag(id, options)
    end

    # Chart type follows the question's format. A Multiple Choice question has a
    # fixed, small set of answers, so a pie reads well; Number and Text answers
    # are open sets and belong in columns.
    def question_chart_tag(chart)
        if chart[:format] == "Multiple Choice"
            pie_chart_tag(chart[:id], title: chart[:title], data: chart[:data])
        else
            column_chart_tag(chart[:id], title: chart[:title], data: chart[:data])
        end
    end

    # Draws every chart inside the given container, or the whole page when no
    # scope is given. Render once, after the chart tags.
    #
    # Scope matters inside a turbo frame: Turbo re-runs this script every time
    # it replaces the frame, so a document-wide selector would also re-draw any
    # chart living outside the frame. Turbo's Range-based replacement also drops
    # the old chart divs without telling Highcharts, which keeps every discarded
    # instance and its detached SVG alive, so sweep those first.
    def chart_script_tag(scope: nil)
        root = scope ? "document.getElementById(#{scope.to_json})" : "document"

        javascript_tag <<~JS
            (function (root) {
                if (!root) { return; }

                (Highcharts.charts || []).forEach(function (chart) {
                    if (chart && !document.body.contains(chart.renderTo)) { chart.destroy(); }
                });

                root.querySelectorAll("[data-highchart]").forEach(function (container) {
                    Highcharts.chart(container.id, JSON.parse(container.dataset.highchart));
                });
            })(#{root});
        JS
    end

    private

        def chart_tag(id, options)
            tag.div(id: id, style: CHART_STYLE, data: { highchart: options.to_json })
        end

        def series_per_answer(data)
            data.map { |answer, count| { name: answer, data: [count] } }
        end
end
