analytics_settings = YAML.load_file("#{::Rails.root}/config/analytics.yml")[Rails.env]
GA_ACCOUNT = analytics_settings["account_id"]
