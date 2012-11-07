# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "msn/version"

Gem::Specification.new do |s|
  s.name        = "em-msn"
  s.version     = Msn::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ary Borenszweig"]
  s.email       = %q{aborenszweig@manas.com.ar}
  s.homepage    = "http://github.com/manastech/em-msn"
  s.summary     = %q{MSN client (EventMachine + Ruby)}
  s.description = %q{An MSN client for Ruby written on top of EventMachine}

  s.files = [
    "lib/em-msn.rb",
    "lib/msn/authentication_error.rb",
    "lib/msn/message.rb",
    "lib/msn/contact.rb",
    "lib/msn/nexus.rb",
    "lib/msn/messenger.rb",
    "lib/msn/challenge.rb",
    "lib/msn/notification_server.rb",
    "lib/msn/protocol.rb",
    "lib/msn/switchboard.rb",
    "lib/msn/version.rb",
  ]

  s.require_path = "lib"
  s.has_rdoc = false
  s.extra_rdoc_files = ["README.md"]

  s.add_dependency "eventmachine"
  s.add_dependency "rest-client"
  s.add_dependency "nokogiri"
  s.add_dependency "guid"

  s.add_development_dependency "rspec", ["~> 2.7"]
end
