$:.unshift File.expand_path("../lib", __FILE__)
require 'fullname/parser/version'

Gem::Specification.new do |s|
  s.name        = "fullname-parser"
  s.version     = Fullname::Parser::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['xiaohui']
  s.email       = ['xiaohui@zhangxh.net']
  s.homepage    = 'http://github.com/xiaohui-zhangxh/fullname-parser'
  s.summary     = "Split fullname into pieces(prefix/first/middle/last/suffix)"
  s.description = "For parsing people's fullname into pieces(prefix/first/middle/last/suffix)"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
