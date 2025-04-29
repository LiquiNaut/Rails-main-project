Rails.application.routes.draw do
  resources :invoices, except: [:index]
  devise_for :users
  resources :users, except: [:edit, :update, :destroy]
  root "home#index"
  get 'chat', to: 'chat#index'
  post 'chat/ask', to: 'chat#ask'
end
