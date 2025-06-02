class ProjectUser < ApplicationRecord
  belongs_to :project
  belongs_to :user

  enum role: { admin: 0, member: 1 }

  validates :user_id, uniqueness: { scope: :project_id, message: "is already a member of this project" }
end