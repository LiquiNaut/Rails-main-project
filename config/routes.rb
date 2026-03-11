Rails.application.routes.draw do
  resources :invoices, except: [:index]
  devise_for :users
  resources :users, except: [:edit, :update, :destroy]
  root "home#index"

  delete 'chat/:id', to: 'chat#destroy'
  post   'chat/ask', to: 'chat#ask'
  post   'chat/new', to: 'chat#new',  as: 'chat_new'
  get    'chat/:id', to: 'chat#show', as: 'chat_show'
  get    'chat',     to: 'chat#index'
end
