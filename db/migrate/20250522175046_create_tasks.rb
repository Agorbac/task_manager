# db/migrate/20250522175046_create_tasks.rb
class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.date :due_date
      t.boolean :is_checked, default: false
      t.references :project, null: false, foreign_key: true
      t.references :user, foreign_key: true, null: true 
      t.timestamps
    end
  end
end