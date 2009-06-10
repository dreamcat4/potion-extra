# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{potion-extra}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["dreamcat4"]
  s.date = %q{2009-06-10}
  s.email = %q{dreamcat4@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "lib/potion-extra.rb",
    "lib/potion_extra.rb",
    "test/potion_extra_test.rb",
    "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/dreamcat4/potion-extra}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Dreamcat4's hacks, fixes and other personal customizations to potionstore. If you would like to check out potionstore, its recommended to just follow the official upstream repository maintained by Andy Kim.}
  s.test_files = [
    "test/potion_extra_test.rb",
    "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
