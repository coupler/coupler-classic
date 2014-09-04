get '/', to: 'home#index'
get '/projects/new', to: 'projects#new'
post '/projects', to: 'projects#create'
get '/projects/:id', to: 'projects#show'
