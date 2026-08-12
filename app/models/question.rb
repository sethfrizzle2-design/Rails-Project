class Question < ApplicationRecord
    # Option order is meaningful — it is the order the form author entered them,
    # and it drives both the order of the answer choices on the response form and
    # the order of the slices on the chart. Say so rather than relying on rows
    # happening to come back by id.
    has_many :options, -> { order(:id) }, dependent: :destroy
    accepts_nested_attributes_for :options, allow_destroy: true
    attribute :amount, :integer, default: 0

    belongs_to :form, optional: true
end
