# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  before_action :require_user
  before_action :set_project
  before_action :set_task, only: [:edit, :update, :destroy, :toggle_check]
  before_action -> { require_project_member(@project) }, only: [:create, :edit, :update, :destroy, :toggle_check]
  before_action :authorize_task_management, only: [:edit, :update, :destroy]

  def create
    @task = @project.tasks.build(task_params)
    if (@project.status == 'searching' || @project.status == 'urgent') && @project.project_users.where(role: :member).exists?
      @project.update(status: :in_progress)
    end

    if @task.save
      flash[:notice] = "Task was successfully created."
    else
      flash[:alert] = "Task could not be created: #{@task.errors.full_messages.join(', ')}"
    end
    redirect_to project_path(@project)
  end

  def edit
  end

  def update
    if @task.update(task_params)
      flash[:notice] = "Task was successfully updated."
      redirect_to project_path(@project)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    flash[:notice] = "Task was successfully deleted."
    redirect_to project_path(@project), status: :see_other
  end

  def toggle_check
    if @project.status == 'in_progress'
      @task.update(is_checked: !@task.is_checked) # Переключаем состояние
      respond_to do |format|
        format.html { redirect_to project_path(@project), notice: "Task status updated!" }
        format.turbo_stream
      end
    else
      flash[:alert] = "You are not authorized to complete this task."
      redirect_to project_path(@project)
    end
  end


  private

  def set_project
    @project = if params[:project_id]
                 Project.find(params[:project_id])
               else
                 Task.find(params[:id]).project
               end
  end

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :due_date, :user_id, :is_checked)
  end


  def authorize_task_management
    is_creator_or_admin = @project.user == current_user || @project.project_users.exists?(user_id: current_user.id, role: :admin)
    is_assignee = @task.user == current_user

    unless is_creator_or_admin || (is_assignee && @task.user_id.present?)
      flash[:alert] = "You are not authorized to manage this task."
      redirect_to project_path(@project)
    end
  end
end