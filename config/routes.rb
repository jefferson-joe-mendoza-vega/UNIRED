Rails.application.routes.draw do
  resources :categories
  resources :faculties, only: [:index, :new, :create, :destroy]
  root 'publicaciones#index', except: :show
  delete 'publicaciones/:id', to: 'publicaciones#destroy', as: :eliminar_publicacion
  patch "/publicaciones/:id", to: 'publicaciones#update'
  post '/publicaciones', to: 'publicaciones#create'
  get 'buscar_publicaciones', to: 'publicaciones#buscar'
  get '/publicaciones/new', to: 'publicaciones#new', as: :nueva_publicacion
  get '/publicaciones', to: 'publicaciones#index'
  get '/publicaciones/:id', to: 'publicaciones#show', as: :publicacion
  get '/publicaciones/:id/edit', to: 'publicaciones#edit', as: :editar_publicacion
  get '/tendencias', to: 'publicaciones#tendencias'

  resources :socials, only: [:new, :create]  
  # Agregar esta línea para la acción POST
  # config/routes.rb
  resources :reactions, only: [:index, :create]
  get '/reacciones', to: 'reactions#reacciones'


  resources :comments, only: [:create, :destroy]
  resources :responses, only: [:create, :destroy]

  resources :notifications, only: [:index]
  


 

  resources :users, only: [:show, :index], path: '/user', param: :username, as: :usuario
  post '/users/:username/make_leader', to: 'users#make_leader', as: :make_leader
  delete '/user/:username', to: 'users#destroy', as: :eliminar_usuario
  get 'buscar_usuarios', to: 'users#buscar'
  

  
  namespace :authentication, path: '', as: '' do  
    resources :users, only: [:new, :create]
    resources :sessions, only: [:new, :create, :destroy]
    delete 'logout', to: 'sessions#destroy'

  end

end
