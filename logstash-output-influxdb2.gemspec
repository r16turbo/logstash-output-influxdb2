Gem::Specification.new do |s|
  s.name          = 'logstash-output-influxdb2'
  s.version       = '0.1.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Logstash Output Plugin for InfluxDB2'
  s.description   = 'This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program'
  s.homepage      = 'https://github.com/r16turbo/logstash-output-influxdb2'
  s.authors       = ['Issey Yamakoshi']
  s.email         = 'r16turbo@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.1"
  s.add_runtime_dependency "influxdb-client", "~> 2.9"
  s.add_development_dependency "logstash-devutils", "~> 2.5"
end
