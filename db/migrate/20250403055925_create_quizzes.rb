class CreateQuizzes < ActiveRecord::Migration[7.0]
  def change
    create_table :quizzes do |t|
      t.integer :label
      t.string :problem
      t.string :answer

      t.timestamps
    end
  end
end
