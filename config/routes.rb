Rails.application.routes.draw do
  match '/search' => 'search#create', via: [:post, :options]
  match '/search/:key' => 'search#reload', via: [:get, :options]
  match '/search/:key/items/:item_ids' => 'search#items', via: [:get, :options]
end
