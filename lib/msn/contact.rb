# A contact returned from Msn::Messenger#get_contacts.
class Msn::Contact

  # The contact's email
  attr_accessor :email

  # The contact's display name
  attr_accessor :display_name

  # Is the contact in your allow list?
  attr_accessor :allow

  # Is the contact in your blocked list?
  attr_accessor :block

  # Is the contact in your reverse list? (does she has you?)
  attr_accessor :reverse

  # Is the contact in your pending list? (you stil didn't approve her)
  attr_accessor :pending

  # :nodoc:
  def initialize(email, display_name = nil)
    @email = email
    @display_name = display_name
  end

  # :nodoc:
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