require 'sidekiq/web'

Dancercity::Application.routes.draw do
  get 'about' => 'pages#about'
  get 'privacy' => 'pages#privacy'
  get 'terms' => 'pages#terms'

  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'
  
  match 'fb_updates', to: 'sessions#fb_notifications', via: [:get, :post]

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'users#index'

  resources :users, only: :index do
    resources :invitations, only: [:index, :show, :create, :update]
  end

  resources :users, path: '', except: :index

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == 'rasg' && password == 'kiaqloo9sw'
  end

  mount Sidekiq::Web, at: "bg/monitor"

end
