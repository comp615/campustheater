server 'yaledramacoalition.org', user: 'ubuntu', roles: [:web, :app, :db], ssh_options: {keys: %w(~/.ssh/YDCKeypair.pem)}
set :deploy_to, '/rails/campustheater-production'
set :branch, 'steve-cmi'
set :rails_env, 'production'
set :keep_releases, 4