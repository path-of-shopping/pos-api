Rails.application.routes.draw do
  match '/search' => 'search#create', via: [:post, :options]
  match '/search/:key' => 'search#reload', via: [:get]
  match '/search/:key/items/:item_ids' => 'search#items', via: [:get]
end
