class Question < ApplicationRecord
  belongs_to :user
  #これ消したらsaveとかupdate直った
  #でもchatGPTによるといるらしい

  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [500, 500]
  end

  has_many :question_similar_words, dependent: :destroy
  accepts_nested_attributes_for :question_similar_words, allow_destroy: true

  has_many :question_tags, dependent: :destroy
  has_many :tags, through: :question_tags, dependent: :destroy

  has_many :flashcard_questions, dependent: :destroy
  has_many :flashcards, through: :flashcard_questions, dependent: :destroy

  validates :image,   content_type: { in: %w[image/jpeg image/gif image/png],
                                      message: "must be a valid image format" },
                      size:         { less_than: 5.megabytes,
                                      message:   "should be less than 5MB" }
end
