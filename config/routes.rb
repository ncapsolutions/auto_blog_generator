Rails.application.routes.draw do
  devise_for :users
  root 'home#index'
  
  resources :posts do
    collection do
      post :generate_description
      post :generate_ai_image
      post :generate_qa
    end
  end

  get 'dashboard', to: 'dashboard#index'
  
  # API endpoints if needed
  namespace :api do
    namespace :v1 do
      resources :posts, only: [:index]
    end
  end
end
