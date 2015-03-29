set :stage, :production
set :branch, 'production'
set :ssh_options, user: fetch(:application)

server '134.102.201.91', roles: %w{web app db}
