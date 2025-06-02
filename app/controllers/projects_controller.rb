# app/controllers/projects_controller.rb
class ProjectsController < ApplicationController
  before_action :require_user, except: [:dashboard, :index, :show]
  before_action :set_project, only: [:show, :edit, :update, :destroy, :join, :update_status, :take_project]
  before_action -> { require_project_creator_or_admin(@project) }, only: [:edit, :update, :destroy]
  before_action -> { require_project_member(@project) }, only: [:show]

  def dashboard
    @projects_searching = Project.where(status: :searching).order(created_at: :desc).limit(5)
    @projects_urgent = Project.where(status: :urgent).order(end_date: :asc).limit(5)
    
    if logged_in?
      @my_projects_in_progress = Project.where(status: :in_progress)
                                      .joins("LEFT JOIN project_users ON project_users.project_id = projects.id")
                                      .where("projects.user_id = :user_id OR project_users.user_id = :user_id", user_id: current_user.id)
                                      .distinct
                                      .includes(:tasks, :user, :users)
                                      .to_a
                                      
      @my_projects_completed = Project.where(status: :completed)
                                    .joins("LEFT JOIN project_users ON project_users.project_id = projects.id")
                                    .where("projects.user_id = :user_id OR project_users.user_id = :user_id", user_id: current_user.id)
                                    .distinct
                                    .includes(:tasks, :user, :users)
                                    .to_a 
    else
      @my_projects_in_progress = []
      @my_projects_completed = []
    end
    render 'dashboard'
  end

  def index
    if logged_in?
      @projects = Project.left_joins(:project_users)
                         .where("projects.user_id = :user_id OR project_users.user_id = :user_id", user_id: current_user.id)
                         .distinct
                         .order(Arel.sql("CASE projects.status WHEN #{Project.statuses[:completed]} THEN 1 ELSE 0 END, projects.created_at DESC")) 
                         .includes(:user, :users, :tasks) 
    else
      redirect_to root_path, alert: "You need to log in to view your projects"
    end
  end

  def take_project
    if @project.can_be_taken_by?(current_user)
      @project.update(status: :in_progress)
      @project.project_users.create(user: current_user, role: :member)
      flash[:notice] = "You have successfully taken the project '#{@project.name}'"
    else
      flash[:alert] = "You cannot take this project"
    end
    redirect_to project_path(@project)
  end

  def update_status
    new_status = params[:status].to_sym
    if Project.statuses.key?(new_status)
      if new_status == :completed
        if @project.all_tasks_completed? && params[:project][:result_link].present? 
          if @project.update(status: new_status, result_link: params[:project][:result_link], end_date: Date.today)
            flash[:notice] = "Project marked as completed."
          else
            flash[:alert] = "Could not complete the project: #{@project.errors.full_messages.join(', ')}"
          end
        else
          flash[:alert] = "All tasks must be checked and a result link provided to complete the project." 
        end
      else
        @project.update(status: new_status)
        flash[:notice] = "Project status updated."
      end
    else
      flash[:alert] = "Invalid status." 
    end
    redirect_to project_path(@project)
  end

  def show
    @task = Task.new(project: @project)
    @tasks = @project.tasks.order(:created_at)
    @project_user = @project.project_users.find_by(user: current_user)
  end

  def new
    @project = Project.new(start_date: Date.today)
    @project.tasks.build
  end

  def create
    @project = current_user.projects.new(project_params)  

    if @project.end_date.present? && @project.end_date <= Date.today + 7.days 
      @project.status = :urgent
    else
      @project.status = :searching
    end

    if @project.save
      @project.project_users.create!(user: current_user, role: :admin) 
      flash[:notice] = "Project was successfully created."
      redirect_to @project 
    else
      @project.tasks.build if @project.tasks.reject(&:marked_for_destruction?).empty?
      flash.now[:error] = @project.errors.full_messages.join(', ')
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @project.tasks.build if @project.tasks.empty?
  end

  def update
    if @project.update(project_params)
      flash[:notice] = "Project was successfully updated."
      redirect_to @project 
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    flash[:notice] = "Project was successfully deleted."
    redirect_to projects_path, status: :see_other 
  end

  def join
    if @project.status == 'searching' || @project.status == 'urgent' 
      unless @project.users.include?(current_user)
        @project.project_users.create(user: current_user, role: :member)
        flash[:notice] = "You have joined the project '#{@project.name}'."
      else 
        flash[:alert] = "You are already a member of this project." 
      end
    else
      flash[:alert] = "This project is not available to join." 
    end
    redirect_to project_path(@project)
  end

  def update_status
    new_status = params[:status].to_sym
    if Project.statuses.key?(new_status)
      if new_status == :completed
        if @project.all_tasks_completed? && params[:project][:result_link].present? 
          if @project.update(status: new_status, result_link: params[:project][:result_link], end_date: Date.today)
            flash[:notice] = "Project marked as completed."
          else
            flash[:alert] = "Could not complete the project: #{@project.errors.full_messages.join(', ')}"
          end
        else
          flash[:alert] = "All tasks must be checked and a result link provided to complete the project." 
        end
      else
        @project.update(status: new_status)
        flash[:notice] = "Project status updated."
      end
    else
      flash[:alert] = "Invalid status." 
    end
    redirect_to project_path(@project)
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(
      :name,
      :description,
      :start_date,
      :end_date,
      tasks_attributes: [
        :id,
        :title,
        :description,
        :_destroy
      ]
    ) 
  end
end