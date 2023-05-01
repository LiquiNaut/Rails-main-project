Rails.application.routes.draw do
  resources :invoices
  devise_for :users
  root "home#index"
end
