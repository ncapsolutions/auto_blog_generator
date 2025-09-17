class AddSerializedColumnsToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :keywords, :text unless column_exists?(:posts, :keywords)
    add_column :posts, :links,    :text unless column_exists?(:posts, :links)
    add_column :posts, :questions, :text unless column_exists?(:posts, :questions)
    add_column :posts, :answers,   :text unless column_exists?(:posts, :answers)
  end
end
