# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gpsoauth4r/version'

Gem::Specification.new do |spec|
  spec.name          = "gpsoauth4r"
  spec.version       = Gpsoauth4r::VERSION
  spec.authors       = ["Christian Köstlin"]
  spec.email         = ["christian.koestlin@esrlabs.com"]

  spec.summary       = %q{Google Play Services for Ruby.}
  spec.description   = %q{Heavily inspored by gmusicapi and gpsoauth by ...}
  spec.homepage      = "https://."
  spec.add_dependency('httparty')
  spec.add_dependency 'terminal-table'
  spec.add_dependency 'highline'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-nc"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
end
