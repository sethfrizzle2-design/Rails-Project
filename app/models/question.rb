class Question < ApplicationRecord
    has_many :options, dependent: :destroy
    accepts_nested_attributes_for :options, allow_destroy: true
    attribute :amount, :integer, default: 0

    belongs_to :form, optional: true
 
end
