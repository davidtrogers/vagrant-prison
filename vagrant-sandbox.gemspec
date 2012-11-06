# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant/sandbox/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-sandbox"
  gem.version       = Vagrant::Sandbox::VERSION
  gem.authors       = ["Erik Hollensbe"]
  gem.email         = ["erik+github@hollensbe.org"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'vagrant', '~> 1.0.5'
  gem.add_dependency 'ruby_parser', '~> 3.0.1'
  gem.add_dependency 'ruby2ruby', '~> 2.0.1'
end
