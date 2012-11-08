# :nodoc:
class Msn::NotificationServer < EventMachine::Connection
  include Msn::Protocol

  ContactsNamespace = {'ns' => 'http://www.msn.com/webservices/AddressBook'}

  attr_reader :messenger
  attr_reader :guid

  def initialize(messenger)
    @messenger = messenger
    @guid = Guid.new.to_s
    @switchboards = {}

    @message_id = 1
    @message_ids = {}

    on_event 'ADL' do |header, data|
      data = Nokogiri::XML(data)
      domain = data.xpath('//ml/d').first['n']
      c = data.xpath('//ml/d/c').first
      username = c['n']
      display_name = c['f']
      messenger.contact_request "#{username}@#{domain}", display_name
    end
  end

  def username_guid
    @username_guid ||= "#{messenger.username};{#{guid}}"
  end

  def send_message(email, text)
    message_id = @message_id
    @message_id += 1

    switchboard = @switchboards[email]
    if switchboard
      trid = switchboard.send_message text
      @message_ids[trid] = message_id
    else
      Fiber.new do
        response = xfr "SB"
        switchboard = create_switchboard email, response[3]
        switchboard.on_event 'JOI' do
          switchboard.clear_event 'JOI'
          trid = switchboard.send_message text
          @message_ids[trid] = message_id
        end
        switchboard.usr username_guid, response[5]
        cal_response = switchboard.cal email
        if cal_response[0] == '217'
          messenger.accept_message_ack message_id, :offline
        end
      end.resume
    end

    message_id
  end

  def username
    messenger.username
  end

  def password
    messenger.password
  end

  def get_contacts
    contacts = {}

    xml = Nokogiri::XML(get_soap_contacts.body)
    xml.xpath('//ns:Membership', ContactsNamespace).each do |membership|
      role = membership.xpath('ns:MemberRole', ContactsNamespace).text
      membership.xpath('ns:Members/ns:Member', ContactsNamespace).each do |member|
        cid = member.xpath('ns:CID', ContactsNamespace).text
        email = member.xpath('ns:PassportName', ContactsNamespace).text
        display_name = member.xpath('ns:DisplayName', ContactsNamespace)

        contact = contacts[cid] ||= Msn::Contact.new(email, display_name ? display_name.text : nil)
        case role
        when 'Allow' then contact.allow = true
        when 'Block' then contact.block = true
        when 'Reverse' then contact.reverse = true
        when 'Pending' then contact.pending = true
        end
      end
    end

    contacts.values
  end

  def get_soap_contacts
    msn_get_contacts_template_file = File.expand_path('../soap/msn_get_contacts_template.xml', __FILE__)
    msn_get_contacts_template = ERB.new File.read(msn_get_contacts_template_file)
    soap = msn_get_contacts_template.result(binding)

    RestClient.post "https://local-bay.contacts.msn.com/abservice/SharingService.asmx", soap, {
      'SOAPAction' => 'http://www.msn.com/webservices/AddressBook/FindMembership',
      'Content-Type' => 'text/xml',
    }
  end

  def post_init
    super

    login
  end

  def login
    Fiber.new do
      begin
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
      rescue Msn::AuthenticationError => ex
        messenger.login_failed(ex.message)
        close_connection
      end
    end.resume
  end

  def login_to_nexus(policy, nonce)
    @nexus = Msn::Nexus.new self, policy, nonce

    first_msg = true
    on_event('MSG') do
      if first_msg
        first_msg = false
        messenger.ready
      end
    end

    on_event('RNG') do |header|
      switchboard = create_switchboard header[5], header[2]
      switchboard.ans username_guid, header[4], header[1]
    end

    response = usr "SSO", "S", @nexus.sso_token, @nexus.secret, guid
    if response[2] != "OK"
      raise Msn::AuthenticationError.new("Didn't receive OK from SSO")
    end
  end

  def create_switchboard(email, host_and_port)
    host, port = host_and_port.split(':')
    switchboard = EM.connect host, port, Msn::Switchboard, messenger
    switchboard.on_event 'ACK' do |header|
      notify_ack header[1].to_i, :ack
    end
    switchboard.on_event 'NAK' do |header|
      notify_ack header[1].to_i, :nak
    end
    switchboard.on_event 'BYE' do |header|
      destroy_switchboard email if header[1] =~ /#{email}/
    end
    @switchboards[email] = switchboard
  end

  def destroy_switchboard(email)
    switchboard = @switchboards.delete email
    switchboard.close_connection if switchboard
  end

  def notify_ack(trid, status)
    id = @message_ids.delete(trid)
    messenger.accept_message_ack id, status if id
  end

  def unbind
    if @reconnect_host
      reconnect @reconnect_host, @reconnect_port.to_i
      @reconnect_host = @reconnect_port = nil
      login
    else
      messenger.disconnected
    end
  end
end
