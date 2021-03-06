Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :users, only: [:create, :edit, :update, :show]

  resources :teams, only: [:create, :show] do
    resources :projects, only: [:index, :new, :create]
    resources :events, only: :index
  end

  resources :projects, only: [:show, :edit, :update, :destroy] do
    post :do_archived, :do_unarchived, on: :member

    resources :todos, only: [:new, :create]
  end

  resources :todos, only: [:show, :edit, :update, :destroy] do
    post :do_runing, :do_pause, :do_completed, :do_reorder, :recover, on: :member

    resources :comments, only: [:new, :create]
  end

  resources :comments, only: [:edit, :update, :destroy]
end
