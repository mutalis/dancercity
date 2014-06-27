require 'sidekiq/web'

Dancercity::Application.routes.draw do
  get 'fb_notifications/send_message', as: 'fb_notifications_send'
  get 'fb_notifications/post_to_wall', as: 'fb_notifications_wall'
  get 'about' => 'pages#about'
  get 'privacy' => 'pages#privacy'
  get 'terms' => 'pages#terms'

  get 'contact' => 'contact_message#new'
  post 'contact' => 'contact_message#create', as: 'contact_messages'

  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'
  get 'auth/facebook', as: 'signin'
  
  match 'fb_updates', to: 'sessions#fb_notifications', via: [:get, :post]

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'users#index'

  resources :users, only: :index do
    resources :invitations, only: [:index, :show, :create, :update]
  end

  resources :users, path: '', except: :index

  # TheComments routes
   concern   :user_comments,  TheComments::UserRoutes.new
   resources :comments, concerns:  [:user_comments]

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == 'rasg' && password == 'kiaqloo9sw'
  end

  mount Sidekiq::Web, at: "bg/monitor"

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "bg/mail"
  end
end
