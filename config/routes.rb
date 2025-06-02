# config/routes.rb
Rails.application.routes.draw do
  root 'projects#dashboard' 

  resources :projects do
    member do
      post 'take_project'
      patch 'submit_result'
      post 'join'
      patch 'update_status'
      patch 'update_tasks'
    end
    resources :tasks, only: [:update, :create, :destroy], shallow: true do
      member do
        patch :toggle_check
      end
    end
  end

  get '/login', to: 'sessions#new', as: 'login'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy', as: 'logout'
  
  get '/signup', to: 'users#new', as: 'new_user'
  post '/signup', to: 'users#create'

  mount ActionCable.server => '/cable'
  get "up" => "rails/health#show", as: :rails_health_check
end