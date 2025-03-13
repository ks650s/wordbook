class CreateQuestionSimilarWords < ActiveRecord::Migration[7.0]
  def change
    create_table :question_similar_words do |t|
      t.string :similar_word
      t.references :question, null: false, foreign_key: true
    end
  end
end
