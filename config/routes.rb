SolidMetrics::Engine.routes.draw do
  resources :queries, only: [:index, :show]
end
