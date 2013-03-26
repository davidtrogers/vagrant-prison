# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant/prison/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-prison"
  gem.version       = Vagrant::Prison::VERSION
  gem.authors       = ["Erik Hollensbe"]
  gem.email         = ["erik+github@hollensbe.org"]
  gem.description   = %q{A programmatic way to configure and sandbox Vagrant}
  gem.summary       = %q{A programmatic way to configure and sandbox Vagrant}
  gem.homepage      = "https://github.com/chef-workflow/vagrant-prison"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'vagrant-fixed-ssh', '~> 1.0.7'
end
