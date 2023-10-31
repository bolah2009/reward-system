Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  post :rewards, to: 'rewards_system#reward_points'
end
