class Question < ApplicationRecord
  has_many :question_tags
  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [500, 500]
  end
  has_many :question_similar_words
  accepts_nested_attributes_for :question_similar_words, allow_destroy: true
  has_many :tags, through: :question_tags
  validates :image,   content_type: { in: %w[image/jpeg image/gif image/png],
                                      message: "must be a valid image format" },
                      size:         { less_than: 5.megabytes,
                                      message:   "should be less than 5MB" }
end
