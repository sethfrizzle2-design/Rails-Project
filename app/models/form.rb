class Form < ApplicationRecord
    has_many :questions, dependent: :destroy
    accepts_nested_attributes_for :questions, allow_destroy: true

    validates :name, uniqueness: true
end
