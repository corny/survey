set :stage, :production
set :ssh_options, user: fetch(:application)

server '91.202.41.201', roles: %w{web app db}
