$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "timeline/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "redis-timeline"
  s.version     = Timeline::VERSION
  s.authors     = ["Felix Clack"]
  s.email       = ["felixclack@gmail.com"]
  s.homepage    = "http://felixclack.github.com/redis-timeline"
  s.summary     = "Redis backed timeline for your activity feeds."
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "activesupport", "~>3.2"
  s.add_dependency "activemodel", "~>3.2"
  s.add_dependency "multi_json"
  s.add_dependency "redis"
  s.add_dependency "hashie"
  s.add_dependency "redis-namespace"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
end
