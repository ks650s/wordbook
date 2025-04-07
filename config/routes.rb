Rails.application.routes.draw do
  # 単語帳問題一覧（メイン）
  get '/index', to: "flashcards#index"
  # 単語帳「新しく単語帳を始める」
  get '/new', to: "flashcards#new"
  # 単語帳「続きから」
  get "/index", to: "tags#index"

  get "/new", to: "tags#new" 
  get "/create", to: "tags#create"

  get "/index", to: "questions#index"
  get "/new", to: "questions#new" 
  get "/create", to: "questions#create"

  get 'sessions/new'
  get "/signup", to: "users#new"
  root "sessions#new"
  
  get    "/login",   to: "sessions#new"
  post   "/login",   to: "sessions#create"
  delete "/logout",  to: "sessions#destroy", as: "logout"
  get "/search", to: "searches#search"
  resources :users
  resources :tags
  resources :questions
  resources :question_similar_words
  resources :flashcards
  resources :quizzes
end
