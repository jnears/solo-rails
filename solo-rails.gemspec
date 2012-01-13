# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "solo-rails/version"

Gem::Specification.new do |s|
  s.name        = "solo-rails"
  s.version     = Solo::Rails::VERSION
  s.authors     = ["Paul Groves"]
  s.email       = ["github@modagoo.co.uk"]
  s.homepage    = ""
  s.summary     = "Ruby wrapper for Soutron Solo API"
  s.description = "Provides methods to query Soutron Solo catalog from Ruby"

  s.rubyforge_project = "solo-rails"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "chronic"
end
