# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'propeller/version'

Gem::Specification.new do |spec|
  spec.name          = "propeller"
  spec.version       = Propeller::VERSION
  spec.authors       = ["Mauricio Giraldo"]
  spec.email         = ["mgiraldo@gmail.com"]
  spec.description   = "Basic Gem to query URLs in parallel"
  spec.summary       = "Using a basic Yaml file, Propeller can dispatch parallel request to a number of urls and collects the results in a hash or in a Junit formatted xml"
  spec.homepage      = "https://github.com/giraldomauricio/propeller"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  #spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.executables   = ["propeller"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "parallel"
  spec.add_development_dependency "httparty"
end
