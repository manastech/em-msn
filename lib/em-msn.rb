module Msn
end

require 'eventmachine'
require 'rest-client'
require 'fiber'
require 'cgi'
require 'digest/md5'

require_relative 'msn/protocol'
require_relative 'msn/message'
require_relative 'msn/notification_server'
require_relative 'msn/switchboard'
require_relative 'msn/messenger'
