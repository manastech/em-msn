class Msn::Messenger
  attr_reader :username
  attr_reader :password

  def initialize(username, password)
    @username = username
    @password = password
  end

  def connect
    @notification_server = EM.connect 'messenger.hotmail.com', 1863, Msn::NotificationServer, self
  end

  def set_online_status(status)
    case status
    when :available, :online
      @notification_server.chg "NLN", 0
    when :busy
      @notification_server.chg "BSY", 0
    when :idle
      @notification_server.chg "IDL", 0
    when :brb, :be_right_back
      @notification_server.chg "BRB", 0
    when :away
      @notification_server.chg "AWY", 0
    when :phone, :on_the_phone
      @notification_server.chg "PHN", 0
    when :lunch, :out_to_lunch
      @notification_server.chg "LUN", 0
    else
      raise "Wrong online status: #{status}"
    end
  end

  def add_contact(email)
    send_contact_command email, 'ADL', '1'
  end

  def remove_contact(email)
    send_contact_command email, 'RML', '1'
  end

  def block_contact(email)
    send_contact_command email, 'RML', '2'
  end

  def unblock_contact(email)
    send_contact_command email, 'ADL', '2'
  end

  def get_contacts
    @notification_server.get_contacts
  end

  def send_contact_command(email, command, list)
    username, domain = email.split '@', 2
    @notification_server.send_payload_command_and_wait command, %Q(<ml><d n="#{domain}"><c n="#{username}" t="1" l="#{list}" /></d></ml>)
  end

  def on_ready(&handler)
    @on_ready_handler = handler
  end

  def on_login_failed(&handler)
    @on_login_failed = handler
  end

  def on_disconnect(&handler)
    @on_disconnect = handler
  end

  def on_message(&handler)
    @on_message_handler = handler
  end

  def on_contact_request(&handler)
    @on_contact_request = handler
  end

  def send_message(email, text)
    @notification_server.send_message email, text
  end

  def accept_message(message)
    call_handler @on_message_handler, message
  end

  def contact_request(email, display_name)
    call_handler @on_contact_request, email, display_name
  end

  def ready
    call_handler @on_ready_handler
  end

  def login_failed(message)
    call_handler @on_login_failed, message
  end

  def disconnected
    call_handler @on_disconnect
  end

  def call_handler(handler, *args)
    if handler
      Fiber.new { handler.call(*args) }.resume
    end
  end

  def self.debug
    @debug
  end

  def self.debug=(debug)
    @debug = debug
  end
end

