# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "antlr4/version"

Gem::Specification.new do |s|
  s.name        = "antlr4" 
  s.version     = Antlr4::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chad Slaughter"]
  s.email       = ["chad.slaughter+antlr4@gmail.com"]
  s.homepage    = "https://github.com/slaught/antlr4-ruby"
  s.summary     = %q{Ruby implementation of the Antlr4 runtime}
  s.description = %q{Ruby implementation of the Antlr4 runtime.
This is needed by any parser/lexer written in Antlr4 and generated with
langague=Ruby.  }

#  s.add_dependency ""

  s.files         = `git ls-files -- lib/* LICENSE README.md`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

