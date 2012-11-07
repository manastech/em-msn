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

  def send_message(text)
    send_payload_command "MSG", "A", "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\nUser-Agent: pidgin/2.10.5devel\r\nX-MMS-IM-Format: FN=Segoe%20UI; EF=; CO=0; PF=0; RL=0\r\n\r\n#{text}"
  end
end

