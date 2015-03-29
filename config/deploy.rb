
set :application, 'tlsscan'
set :repo_url,    'https://github.com/corny/tlspolicy.git'
set :deploy_to,   '/home/tlsscan'
set :log_level,   :info

# Symlink files
set :linked_files, fetch(:linked_files, []).push('config/secrets.yml')

# Symlink directories
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'data')
