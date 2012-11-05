class Msn::NotificationServer < EventMachine::Connection
  include Msn::Protocol

  attr_reader :messenger
  attr_reader :display_name
  attr_reader :guid

  def initialize(messenger)
    @messenger = messenger
    @guid = Guid.new.to_s
    @switchboards = {}

    on_event 'ADD' do |header|
      if header[3] =~ /\A\d+\Z/
        messenger.contact_request header[4], header[5]
      else
        messenger.contact_request header[3], header[4]
      end
    end
  end

  def username_guid
    @username_guid ||= "#{messenger.username};{#{guid}}"
  end

  def send_message(email, text)
    switchboard = @switchboards[email]
    if switchboard
      switchboard.send_message text
    else
      Fiber.new do
        response = xfr "SB"
        switchboard = create_switchboard email, response[3]
        switchboard.on_event 'JOI' do
          switchboard.clear_event 'JOI'
          switchboard.send_message text
        end
        switchboard.usr username_guid, response[5]
        switchboard.cal email
      end.resume
    end
  end

  def username
    messenger.username
  end

  def password
    messenger.password
  end

  def post_init
    super

    login
  end

  def login
    Fiber.new do
      ver "MSNP18", "CVR0"
      cvr "0x0409", "winnt", "5.1", "i386", "MSNMSGR", "8.5.1302", "BC01", username
      response = usr "SSO", "I", username
      if response[0] == "XFR" && response[2] == "NS"
        host, port = response[3].split ':'
        @reconnect_host, @reconnect_port = response[3].split ':'
        close_connection
      else
        login_to_nexus(response[4], response[5])
      end
    end.resume
  end

  def login_to_nexus(policy, nonce)
    nexus = Msn::Nexus.new policy, nonce
    token, return_value = nexus.login messenger.username, messenger.password

    on_event('RNG') do |header|
      switchboard = create_switchboard header[5], header[2]
      switchboard.ans username_guid, header[4], header[1]
    end

    response = usr "SSO", "S", token, return_value, guid
    if response[2] != "OK"
      raise "Login failed (3)"
    end

    messenger.ready

    @display_name = CGI.unescape response[4]
  end

  def create_switchboard(email, host_and_port)
    host, port = host_and_port.split(':')
    switchboard = EM.connect host, port, Msn::Switchboard, messenger
    switchboard.on_event 'BYE' do |header|
      destroy_switchboard email if header[1] =~ /#{email}/
    end
    @switchboards[email] = switchboard
  end

  def destroy_switchboard(email)
    switchboard = @switchboards.delete email
    switchboard.close_connection
  end

  def unbind
    if @reconnect_host
      reconnect @reconnect_host, @reconnect_port.to_i
      @reconnect_host = @reconnect_port = nil
      login
    end
  end
end
