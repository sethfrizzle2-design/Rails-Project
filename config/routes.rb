Rails.application.routes.draw do
  get 'testsites/pages'
  get 'testsites/one'
  get 'testsites/two'
  get 'testsites/three'
  get 'testsites/four'

  root "articles#index"

  resources :articles
  
  get 'sign_up', to: 'users#new', as: :sign_up
  post 'sign_up', to: 'users#create'
  
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
  get "logout", to: "sessions#destroy"

  get 'bus_make', to: 'buses#new', as: :bus_make
  post 'bus_make', to: 'buses#create'

  get 'bus_search', to: 'buses#show', as: :bus_search
  
  get 'show', to: 'buses#show'
  
  get 'buses/test'



  

  

  get 'new_bigs', to: 'bigs#new', as: :new_bigs
  post 'new_bigs', to: 'bigs#create'

  resources :forms

  resources :questions, only: [:create, :destroy] do 
    collection do 
      delete :remove
    end
  end

  resources :options, only: [:create, :destroy] do 
    collection do 
      delete :remove
    end
  end

  get 'home', to: 'forms#index', as: :home

  get 'build_form', to: 'builders#show', as: :build_form



  get 'form_response', to: 'responses#new', as: :form_response
  post 'form_response', to: 'responses#new'

  get 'response_view', to: 'responses#show', as: :response_view
  post 'response_view', to: 'responses#show'

  get 'response_chart', to: 'responses#chart', as: :response_chart
  post 'response_chart', to: 'responses#chart'

  

  resources :responses


  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
