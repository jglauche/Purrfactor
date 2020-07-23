# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'purrfactor'

Gem::Specification.new do |s|
  s.name = 'purrfactor'
  s.version  = '0.0.1'
  s.authors = ['Jennifer Glauche']
  s.email = "=^.^=@purrfactor.kittenme.ws"
  s.description = %q{TBD}
  s.summary = %q{TBD}

  s.license     = 'LGPL-3'
  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 2.6.0"

  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "optimist"
  s.add_runtime_dependency "haml_parser"
  s.add_runtime_dependency "parser"
  s.add_runtime_dependency "html2haml"
end
