Rails.application.routes.draw do
  get '/flashcards/index', to: "flashcards#index"
  get '/tags/index', to: "tags#index"
  get '/questions/index', to: "questions#index", as: 'questions_index'


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

  resources :searches do
    collection do
      patch 'searchtagflag'
    end
  end

  post '/submit_current_answer', to: 'flashcards#submit_current_answer', as: :submit_current_answer
  resources :users
  resources :tags
  resources :questions
  resources :question_similar_words
  post '/flashcards/start_session', to: 'flashcards#start_session', as: :start_session_flashcards
  resources :flashcards do
    collection do
      get 'result'
      get 'question_session', to: 'flashcards#question_session'
      post 'submit_session_answer', to: 'flashcards#submit_session_answer'
      get 'result_session', to: 'flashcards#result_session'
      post 'interrupt', to: 'flashcards#interrupt'
      get :ranking
      post 'finalize_session', to: 'flashcards#finalize_session'
    end

    
    member do
      post :reset
      get 'result', to: 'flashcards#result'
      get 'resume'
      
    end
  end
end
