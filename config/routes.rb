Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :teams, only: :create do
    resources :projects, only: [:index, :new, :create]
    resources :events, only: :index
  end

  resources :projects, only: [:show, :edit, :update, :destroy] do
    post :do_archived, :do_unarchived, on: :member
  end
end
