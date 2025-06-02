class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

def current_user
  @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
end

def logged_in?
  !!current_user
end

def current_project_user(project)
  project.project_users.find_by(user: current_user)
end

def require_user
  unless logged_in?
    flash[:alert] = "You must be logged in to perform that action."
    redirect_to login_path
  end
end

  def require_project_creator_or_admin(project)
    unless current_user == project.user || project.project_users.exists?(user: current_user, role: :admin)
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to project_path(project)
    end
  end

  def require_project_member(project)
    return if project.searching? || project.urgent?
    
    unless project.users.include?(current_user) || current_user == project.user
      flash[:alert] = "You are not a member of this project."
      redirect_to projects_path
    end
  end
end