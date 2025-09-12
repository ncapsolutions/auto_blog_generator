class AddWordpressIdToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :wordpress_id, :integer
    add_index :posts, :wordpress_id
  end
end
