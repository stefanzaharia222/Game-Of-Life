Rails.application.routes.draw do
  root 'game_of_life#index'
  post 'load_file', to: 'game_of_life#load_file'
  post 'next_generation', to: 'game_of_life#calculate_next_generation'
end