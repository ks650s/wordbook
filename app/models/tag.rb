class Tag < ApplicationRecord
  validates :name,  presence: true, uniqueness: { case_sensitive: false }
  has_many :question_tags
  has_many :questions, through: :question_tags
  belongs_to :user
end
