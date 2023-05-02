Rails.application.routes.draw do
  resources :invoices, except: [:index]
  devise_for :users
  resources :users, except: [:edit, :update, :destroy]
  root "home#index"
end
