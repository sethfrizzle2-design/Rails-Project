class Response < ApplicationRecord
    has_many :inputs, dependent: :destroy
    accepts_nested_attributes_for :inputs, allow_destroy: true
end
