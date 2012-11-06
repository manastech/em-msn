class Msn::Contact
  attr_accessor :email
  attr_accessor :display_name
  attr_accessor :allow
  attr_accessor :block
  attr_accessor :reverse
  attr_accessor :pending

  def initialize(email, display_name = nil)
    @email = email
    @display_name = display_name
  end

  def to_s
    if display_name && display_name.length > 0
      str = "#{display_name} <#{email}>"
    else
      str = "#{email}"
    end
    if allow || reverse || pending
      str << ' ('
      pieces = []
      pieces << 'allow' if allow
      pieces << 'block' if block
      pieces << 'reverse' if reverse
      pieces << 'pending' if pending
      str << pieces.join(', ')
      str << ')'
    end
    str
  end
end