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

  def on_ready(&handler)
    @on_ready_handler = handler
  end

  def on_message(&handler)
    @on_message_handler = handler
  end

  def send_message(email, text)
    @notification_server.send_message email, text
  end

  def accept_message(message)
    if @on_message_handler
      Fiber.new { @on_message_handler.call(message) }.resume
    end
  end

  def ready
    if @on_ready_handler
      Fiber.new { @on_ready_handler.call }.resume
    end
  end

  def self.debug
    @debug
  end

  def self.debug=(debug)
    @debug = debug
  end
end

