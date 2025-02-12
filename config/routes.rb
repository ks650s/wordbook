Rails.application.routes.draw do
  get "/signup", to: "users#new"
  root "hello#index"
  resources :users
end
