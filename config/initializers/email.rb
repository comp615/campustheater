email_settings = YAML.load_file("#{::Rails.root}/config/email.yml")

YDC_EMAIL = email_settings["address"]
EMAIL_USERNAME = email_settings["username"]
EMAIL_PASSWORD = email_settings["password"]
EMAIL_DOMAIN = email_settings["domain"]