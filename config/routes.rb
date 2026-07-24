Rails.application.routes.draw do
  # Authentication
  get "login", to: "pages#login", as: :login
  get "/auth/google_oauth2/callback", to: "sessions#create"
  get "/auth/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "logout", to: "sessions#destroy", as: :logout

  # Dashboard
  root "dashboard#index"

  # Assets & Quotes
  resources :assets, path: "instruments", only: [ :index, :show ]
  resources :quotes, only: [ :index ]

  # Watchlist
  resources :watchlists, only: [ :index, :create, :destroy ]

  # Portfolios
  resources :portfolios do
    resources :positions, only: [ :index, :show ]
    resources :transactions, only: [ :index, :create, :destroy ]
  end

  # Exports
  get "exports", to: "exports#index"
  get "exports/csv", to: "exports#csv"
  get "exports/json", to: "exports#json"
  get "exports/download", to: "exports#download"
  get "exports/report", to: "exports#report"

  # API namespace for Turbo/JSON endpoints
  namespace :api do
    resources :quotes, only: [ :index, :show ]
    get "signals", to: "signals#index"
    get "scoring", to: "scoring#index"
    get "health/data", to: "health#data"
    get "sectors", to: "sectors#index"
    get "movers", to: "movers#index"
    get "news", to: "news#index"
    get "report", to: "report#show"
    post "refresh", to: "refresh#create"

    resources :watchlists, path: "watchlist", only: [ :index, :create, :destroy ]
    resources :portfolios do
      member do
        get :performance
      end
      resources :positions, only: [ :index ], controller: "portfolio_positions"
      resources :transactions, only: [ :index, :create, :destroy ], controller: "portfolio_transactions"
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
