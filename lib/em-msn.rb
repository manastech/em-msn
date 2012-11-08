module Msn
  # :nodoc:
  ApplicationId = "CFE80F9D-180F-4399-82AB-413F33A1FA11"
end

require 'eventmachine'
require 'rest-client'
require 'fiber'
require 'cgi'
require 'guid'
require 'base64'
require 'digest/md5'
require 'digest/hmac'
require 'erb'
require "nokogiri"
require 'rexml/text'

require_relative 'msn/authentication_error'
require_relative 'msn/protocol'
require_relative 'msn/message'
require_relative 'msn/contact'
require_relative 'msn/nexus'
require_relative 'msn/challenge'
require_relative 'msn/notification_server'
require_relative 'msn/switchboard'
require_relative 'msn/messenger'
