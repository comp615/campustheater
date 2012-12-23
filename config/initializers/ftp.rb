ftp_settings = YAML.load_file("#{::Rails.root}/config/ftp.yml")[Rails.env]

FTP_HOST = ftp_settings["host"]
FTP_USERNAME = ftp_settings["user"]
FTP_PASSWORD = ftp_settings["password"]