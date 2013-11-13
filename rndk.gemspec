# coding: utf-8
# requiring `lib` on load path
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rndk/version'

Gem::Specification.new do |spec|
  spec.name          = 'rndk'
  spec.version       = RNDK::VERSION
  spec.authors       = ["Alexandre Dantas"]
  spec.email         = ["eu@alexdantas.net"]

  spec.summary       = "Ruby Ncurses Development Kit"
  spec.description   = <<END_OF_DESCRIPTION
`rndk` aims to be a powerful, well-documented and easy-to-use
Ncurses Development Kit in Ruby. Besides abstracting away Ncurses'
details, it provides some widgets for rapid console app development.

It means that you'll be able to master the dark arts of text-based
applications, easily creating nice apps for the console.
END_OF_DESCRIPTION

  spec.homepage      = "http://alexdantas.net/projects/rndk"
  spec.license       = "BSD"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi-ncurses"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
