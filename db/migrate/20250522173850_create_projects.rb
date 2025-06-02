class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.date :start_date
      t.date :end_date
      t.integer :status
      t.string :result_link
      t.references :user, foreign_key: true 
      t.timestamps
    end
  end
end