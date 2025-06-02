# app/models/task.rb
class Task < ApplicationRecord
  belongs_to :project
  belongs_to :user, foreign_key: 'assignee_id', optional: true 
  validates :title, presence: true
end