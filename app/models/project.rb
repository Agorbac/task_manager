# app/models/project.rb
class Project < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy
  has_many :project_users, dependent: :destroy
  has_many :users, through: :project_users

  accepts_nested_attributes_for :tasks, 
    allow_destroy: true,
    reject_if: proc { |attrs| attrs['title'].blank? }

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date
  validate :has_at_least_one_valid_task, on: :create

  enum status: { searching: 0, urgent: 1, in_progress: 2, completed: 3 }

  def can_be_taken_by?(user)
    (searching? || urgent?) && user != self.user && !users.include?(user)
  end
  def executor
    project_users.member.first&.user
  end
  def all_tasks_completed?
    tasks.where(is_checked: false).none?
  end

  def all_tasks_completed?
    tasks.where(is_checked: false).none?
  end

  def can_be_completed_by?(user)
    in_progress? && 
    (user == self.user || 
     project_users.exists?(user: user, role: :member)) && 
    all_tasks_completed?
  end

  private

  
  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def has_at_least_one_valid_task
    valid_tasks = tasks.reject do |task|
      task.marked_for_destruction? || task.title.blank?
    end
    errors.add(:base, "must have at least one valid task") if valid_tasks.empty?
  end
end