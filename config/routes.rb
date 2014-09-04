get '/', to: 'home#index'
get '/projects/new', to: 'projects#new'
post '/projects', to: 'projects#create'
get '/projects/:id', to: 'projects#show'

get '/projects/:project_id/datasets/new', to: 'datasets#new'
