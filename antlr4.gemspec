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
This is needed by any parser/lexer written in Antlr4 using the target 
langague=Ruby.  }

#  s.add_dependency ""
  s.require_paths = ["lib"]
  s.files = Dir[ "lib/*.rb" ] +
            Dir[ "lib/antlr4/*.rb" ] +
            Dir[ "lib/antlr4/*/*.rb" ] +
            Dir[ 'LICENSE' ] +
            Dir[ 'README.md' ]
  s.test_files = Dir[ 'test/*']
  s.executables =  Dir['antlr_testrig' ]
end

