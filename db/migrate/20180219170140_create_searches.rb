class CreateSearches < ActiveRecord::Migration[5.1]
  def change
    create_table :searches do |t|
      t.string :key
      t.string :query_json
      t.datetime :saw_at
      t.datetime :created_at
    end

    add_index :searches, :key
  end
end
