# em-msn

MSN client (EventMachine + Ruby)

## Project Pages

* [Docs](http://rdoc.info/gems/em-msn)
* [GitHub](https://github.com/manastech/em-msn)

# Usage

## Installation

    gem install em-msn

## Gemfile

    gem 'em-msn'

## Example

    require 'rubygems'
    require 'em-msn'

    EM.run do
      EM.schedule do
        msn = Msn::Messenger.new 'johndoe@hotmail.com', 'password'

        msn.on_login_failed do |reason|
          puts "Oops... #{reason}"
        end

        msn.on_ready do
          msn.set_online_status :online
        end

        msn.on_message do |message|
          puts "Got message from #{message.email}: #{message.text}"

          msn.send_message message.email, "Hi #{message.display_name}!"
        end

        msn.on_contact_request do |email, display_name|
          puts "Contact request from #{display_name} <#{email}>"

          msn.add_contact email
        end

        msn.connect
      end
    end

# Contributions

All contributions are welcome. The gem doesn't have many tests and a lot of things
can be improved, as some parts of the protocol are not yet implemented.

# Author

[Ary Borenszweig](http://github.com/asterite)