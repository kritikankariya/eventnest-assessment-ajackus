Rails.application.routes.draw do
  resources :events do
    # Add these nested routes
    resources :bookmarks, only: [:create, :destroy], module: :events
  end
  
  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"

      resources :events do
        resources :ticket_tiers, only: [:index, :create, :update, :destroy]
       member do
          get :bookmark_count
        end
       end

      resources :bookmarks, only: [:index]

      resources :orders, only: [:index, :show, :create] do
        member do
          post :cancel
        end
      end
    end
  end
end
