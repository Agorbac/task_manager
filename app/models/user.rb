# app/models/user.rb
class User < ApplicationRecord
  has_secure_password 

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_many :projects, foreign_key: 'user_id', dependent: :destroy

  has_many :project_users, dependent: :destroy

  has_many :participated_projects, through: :project_users, source: :project

  has_many :assigned_tasks, class_name: 'Task', foreign_key: 'assignee_id', dependent: :nullify 
end