require 'yaml'
require 'rails'

defaultConfig = YAML.load_file('/opt/postal/app/config/postal.example.yml')
linkyardDefault = YAML.load_file('/opt/linkyard/default_config.yml')
userConfig = YAML.load_file('/tmp/user.yml')
secrets = YAML.load_file('/tmp/secrets.yml')

merged = defaultConfig.deep_merge(linkyardDefault)
merged = merged.deep_merge(userConfig)
merged = merged.deep_merge(secrets)

File.open('/opt/postal/config/postal.yml', 'w') { |f| f.write(merged.to_yaml) }
