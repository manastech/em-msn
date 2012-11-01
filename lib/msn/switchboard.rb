class Msn::Switchboard < EventMachine::Connection
  include Msn::Protocol

  def initialize(messenger)
    @messenger = messenger

    on_event 'MSG' do |header, data|
      email = header[1]
      display_name = header[2]
      head, body = data.split "\r\n\r\n", 2
      headers = Hash[head.split("\r\n").map { |line| line.split ':', 2 }]

      if headers['Content-Type'] =~ %r(text/plain)
        @messenger.accept_message Msn::Message.new(email, display_name, body)
      end
    end
  end
end

