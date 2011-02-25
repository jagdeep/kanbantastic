# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "kanbantastic/version"

Gem::Specification.new do |s|
  s.name        = "kanbantastic"
  s.version     = Kanbantastic::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jagdeep Singh"]
  s.email       = ["jagdeepkh@gmail.com"]
  s.homepage    = "https://github.com/Ennova/kanbantastic"
  s.summary     = %q{Gives you methods to manage your kanbanery resources like a project's tasks, columns and more}
  s.description = %q{Use this gem to interact with kanbanery API}

  s.rubyforge_project = "kanbantastic"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.licenses = ["MIT"]
  s.rubygems_version = %q{1.3.7}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]

  s.add_runtime_dependency('activemodel')
  s.add_runtime_dependency('httparty')
end
