class Msn::NotificationServer < EventMachine::Connection
  include Msn::Protocol

  attr_reader :messenger
  attr_reader :display_name

  def initialize(messenger)
    @messenger = messenger
    @switchboards = {}
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
        switchboard.usr messenger.username, response[5]
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
      response = ver "MSNP8"
      if response[2] != "MSNP8"
        raise "Expected response to be 'VER 0 MSNP8' but it was '#{response}'"
      end

      response = cvr "0x0409", "winnt", "5.1", "i386", "MSNMSGR", "6.0.0602", "MSMSGS", username
      if response[2] == "1.0.0000"
        raise "The client version we are sending is not compatible anymore :-("
      end

      response = usr "TWN", "I", username
      if response[0] == "XFR" && response[2] == "NS"
        host, port = response[3].split ':'
        @reconnect_host, @reconnect_port = response[3].split ':'
        close_connection
      else
        login_with_challenge(response[4])
      end
    end.resume
  end

  def login_with_challenge(challenge)
    nexus_response = RestClient.get "https://nexus.passport.com/rdr/pprdr.asp"
    passport_urls = nexus_response.headers[:passporturls]
    passport_urls = Hash[passport_urls.split(',').map { |key_value| key_value.split('=', 2) }]
    passport_url = "https://#{passport_urls['DALogin']}"

    authorization = "Passport1.4 OrgVerb=GET,OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom,sign-in=#{CGI.escape username},pwd=#{CGI.escape password},#{challenge}"
    da_login_response = RestClient.get passport_url, 'Authorization' => authorization
    if da_login_response.net_http_res.code != "200"
      raise "Login failed (1)"
    end

    authentication_info = da_login_response.headers[:authentication_info]
    authentication_info = authentication_info["Passport1.4 ".length .. -1]
    authentication_info = Hash[authentication_info.split(',').map { |key_value| key_value.split('=', 2) }]
    if authentication_info['da-status'] != "success"
      raise "Login failed (2)"
    end

    from_pp = authentication_info['from-PP']
    token = from_pp[1 .. -2] # remove single quotes

    first_msg = true
    on_event('MSG') do
      if first_msg
        first_msg = false
        messenger.ready
      end
    end

    on_event('RNG') do |header|
      switchboard = create_switchboard header[5], header[2]
      switchboard.ans username, header[4], header[1]
    end

    response = usr "TWN", "S", token
    if response[2] != "OK"
      raise "Login failed (3)"
    end

    @display_name = CGI.unescape response[4]
  end

  def create_switchboard(email, host_and_port)
    host, port = host_and_port.split(':')
    switchboard = EM.connect host, port, Msn::Switchboard, messenger
    switchboard.on_event 'BYE' do |header|
      destroy_switchboard email if header[1] == email
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
