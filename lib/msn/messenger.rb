# Main class to communicate with MSN.
class Msn::Messenger
  attr_reader :username
  attr_reader :password

  # Create an MSN connection with a username (email) and password.
  def initialize(username, password)
    @username = username
    @password = password
  end

  # Connects to the MSN server. Event handlers should be set before calling this method.
  def connect
    @notification_server = EM.connect 'messenger.hotmail.com', 1863, Msn::NotificationServer, self
  end

  # Sets your online status. Status can be:
  # * :available, :online
  # * :busy
  # * :idle
  # * :brb, :be_right_back
  # * :away
  # * :phone, :on_the_phone
  # * :lunch, :out_to_lunch
  # It is advisable to call this method as soon as you connect, otherwise you
  # won't be able to perform certain actions (like sending messages).
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

  # Adds a contact. Technically, this adds it to your Friends List.
  def add_contact(email)
    send_contact_command email, 'ADL', '1'
  end

  # Removes a contact. Technically, this removes it from your Friends List.
  def remove_contact(email)
    send_contact_command email, 'RML', '1'
  end

  # Blocks a contact. Technically, this removes it from your Allowed List.
  def block_contact(email)
    send_contact_command email, 'RML', '2'
  end

  # Unblocks a contact. Technically, this adds it to your Allowed List.
  def unblock_contact(email)
    send_contact_command email, 'ADL', '2'
  end

  # Returns all contacts associated to this Messenger account.
  # This is an array of Msn::Contact.
  def get_contacts
    @notification_server.get_contacts
  end

  # Invoked when this Messenger gets connected to the server.
  #
  #     msn.on_ready do
  #       msn.set_online_status :online
  #     end
  def on_ready(&handler)
    @on_ready_handler = handler
  end

  # Invoked when the username/password are incorrect.
  #
  #     msn.on_login_failed do |reason|
  #       puts "Login failed: #{reason} :-("
  #       msn.close
  #     end
  def on_login_failed(&handler)
    @on_login_failed = handler
  end

  # Invoked when this Messenger gets disconnected from the server.
  #
  #     msn.on_disconnect do
  #       # Try to reconnect
  #       msn.connect
  #     end
  def on_disconnect(&handler)
    @on_disconnect = handler
  end

  # Invoked when somebody sends a messages to this account, with an Msn::Message.
  #
  #     msn.on_message do |msg|
  #       # msg is an Msn:Message instance
  #     end
  def on_message(&handler)
    @on_message_handler = handler
  end

  # Invoked after a message is sent by this Messenger, to know
  # what happened with it.
  #
  #     msn.on_message_ack do |message_id, status|
  #       # status can be :ack, :nak or :offline
  #       # message_id is the one you got from send_message
  #     end
  def on_message_ack(&handler)
    @on_message_ack_handler = handler
  end

  # Invoked when there is a contact request.
  #
  #     msn.on_contact_request do |email, display_name|
  #       ...
  #     end
  def on_contact_request(&handler)
    @on_contact_request = handler
  end

  # Sends a message to the given email with the given text.
  # Returns an ID (a number) that can be used to relate the
  # send messages to ACKs.
  def send_message(email, text)
    @notification_server.send_message email, text
  end

  # Closes the connection to the MSN server.
  def close
    @notification_server.close_connection
  end

  # :nodoc:
  def send_contact_command(email, command, list)
    username, domain = email.split '@', 2
    @notification_server.send_payload_command_and_wait command, %Q(<ml><d n="#{domain}"><c n="#{username}" t="1" l="#{list}" /></d></ml>)
  end

  # :nodoc:
  def accept_message(message)
    call_handler @on_message_handler, message
  end

  # :nodoc:
  def accept_message_ack(id, status)
    call_handler @on_message_ack_handler, id, status
  end

  # :nodoc:
  def contact_request(email, display_name)
    call_handler @on_contact_request, email, display_name
  end

  # :nodoc:
  def ready
    call_handler @on_ready_handler
  end

  # :nodoc:
  def login_failed(message)
    call_handler @on_login_failed, message
  end

  # :nodoc:
  def disconnected
    call_handler @on_disconnect
  end

  # :nodoc:
  def call_handler(handler, *args)
    if handler
      Fiber.new { handler.call(*args) }.resume
    end
  end

  # Sets a logger that will get logged as info all communication to the MSN server
  # (but not all communication to the MSN nexus server).
  def self.logger=(logger)
    @logger = logger
  end

  # :nodoc:
  def self.logger
    @logger
  end

  # :nodoc:
  def self.log_info(message)
    return unless logger

    logger.info message
  end
end

