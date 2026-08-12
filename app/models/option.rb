class Option < ApplicationRecord
    belongs_to :question, optional: true
end
