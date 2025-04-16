module FlashcardsHelper
  def flashcard_in_progress?(flashcard)
    flashcard.flashcard_questions.any? { |fq| fq.user_answer.nil? }
  end
end