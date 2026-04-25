class CreateShortLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :short_links do |t|
      t.string :original_url, null: false
      t.string :code, null: false

      t.timestamps
    end

    add_index :short_links, :original_url, unique: true
    add_index :short_links, :code, unique: true
  end
end
