server 'yaledramacoalition.org', user: 'ubuntu', roles: [:web, :app, :db], ssh_options: {keys: %w(~/.ssh/YDCKeypair.pem)}
set :deploy_to, '/rails/campustheater-staging'
set :branch, 'steve-cmi'
set :rails_env, 'staging'
set :keep_releases, 2