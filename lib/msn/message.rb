# A message sent to a Messenger.
class Msn::Message
  attr_accessor :email
  attr_accessor :display_name
  attr_accessor :text

  # :nodoc:
  def initialize(email, display_name, text)
    @email = email
    @display_name = display_name
    @text = text
  end
end