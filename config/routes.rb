Rails.application.routes.draw do
  match '/search' => 'search#create', via: [:post, :options]
  match '/search/:id' => 'search#reload', via: [:get]
  match '/search-items' => 'search#fetch_items', via: [:get]
end
