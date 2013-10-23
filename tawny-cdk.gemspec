# coding: utf-8

# requiring `lib` on load path
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cdk'

Gem::Specification.new do |spec|
  spec.name          = 'cdk'
  spec.version       = CDK.Version
  spec.authors       = ["Chris Sauro"]
#  spec.email         = ["mail@domain.com"]

  spec.summary       = "A ruby port of the Curses Development Kit."
  spec.description   = <<END_OF_DESCRIPTION
A Ruby version of Thomas Dickey version of the curses development kit.

Why Tawny? Because this is better than just a ruby port. Or, rather,
it will be. At the moment it's pretty much just a Ruby port but the
plan is a package that is easier to use and extend, with extra
extensions to prove it.

Currently implemented widgets:

* Alphalist
* Button
* Buttonbox
* Calendar
* Dialog
* Entry
* File Selector
* Graph
* Histogram
* Item List
* Label
* Matrix
* Marquee
* Menu
* Multiple Line Entry
* Radio List
* Scale
* Scrolling List
* Scrolling Window
* Selection List
* Slider
* Template
* Viewer
END_OF_DESCRIPTION

  spec.homepage      = "https://github.com/masterzora/tawny-cdk"
  spec.license       = "BSD"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ncurses-ruby"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
