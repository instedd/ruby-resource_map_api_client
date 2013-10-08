# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'resource_map_api_client/version'

Gem::Specification.new do |spec|
  spec.name          = "resource_map_api_client"
  spec.version       = ResourceMapApiClient::VERSION
  spec.authors       = ["Ary Borenszweig"]
  spec.email         = ["aborenszweig@manas.com.ar"]
  spec.description   = %q{Access the Resource Map API}
  spec.summary       = %q{A Resource Map API client}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "memoist"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
