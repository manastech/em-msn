class Msn::Nexus
  attr_reader :messenger
  attr_reader :policy
  attr_reader :nonce

  Namespaces = {
    "wsse" => "http://schemas.xmlsoap.org/ws/2003/06/secext",
    "wst" => "http://schemas.xmlsoap.org/ws/2004/04/trust",
    "wsp" => "http://schemas.xmlsoap.org/ws/2002/12/policy",
    "wsa" => "http://schemas.xmlsoap.org/ws/2004/03/addressing",
    "S" => "http://schemas.xmlsoap.org/soap/envelope/",
  }

  def initialize(messenger, policy, nonce)
    @messenger = messenger
    @policy = policy
    @nonce = nonce
  end

  def sso_token
    fetch_data
    @sso_token
  end

  def ticket_token
    fetch_data
    @ticket_token
  end

  def secret
    fetch_data
    @secret
  end

  def fetch_data
    return if @fetched_data
    @fetched_data = true

    @sso_token, secret, @ticket_token = get_binary_secret messenger.username, messenger.password

    @secret = compute_return_value secret
  end

  def get_binary_secret(username, password)
    msn_sso_template_file = File.expand_path('../soap/msn_sso_template.xml', __FILE__)
    msn_sso_template = ERB.new File.read(msn_sso_template_file)
    soap = msn_sso_template.result(binding)

    response = RestClient.post "https://login.live.com/RST.srf", soap

    xml = Nokogiri::XML(response)

    # Check invalid login
    fault = xml.xpath("//S:Fault/faultstring")
    if fault
      raise Msn::AuthenticationError.new(fault.text)
    end

    rstr = xml.xpath "//wst:RequestSecurityTokenResponse[wsp:AppliesTo/wsa:EndpointReference/wsa:Address='messengerclear.live.com']", Namespaces
    token = rstr.xpath("wst:RequestedSecurityToken/wsse:BinarySecurityToken[@Id='Compact1']", Namespaces).first.text
    secret = rstr.xpath("wst:RequestedProofToken/wst:BinarySecret", Namespaces).first.text

    rstr2 = xml.xpath "//wst:RequestSecurityTokenResponse[wsp:AppliesTo/wsa:EndpointReference/wsa:Address='contacts.msn.com']", Namespaces
    ticket_token = rstr2.xpath("wst:RequestedSecurityToken/wsse:BinarySecurityToken[@Id='Compact2']", Namespaces).first.text

    [token, secret, ticket_token]
  end

  def compute_return_value(binary_secret, iv = Random.new.bytes(8))
    key1 = Base64.decode64 binary_secret

    key2 = compute_key key1, "WS-SecureConversationSESSION KEY HASH"
    key3 = compute_key key1, "WS-SecureConversationSESSION KEY ENCRYPTION"

    hash = sha1_hmac key2, @nonce

    nonce = "#{@nonce}#{8.chr * 8}"

    des = OpenSSL::Cipher::Cipher.new("des-ede3-cbc")
    des.encrypt
    des.iv = iv
    des.key = key3
    encrypted_data = des.update(nonce) + des.final

    final = [28, 1, 0x6603, 0x8004, 8, 20, 72, iv, hash, encrypted_data].pack "L<L<L<L<L<L<L<A8A20A72"
    Base64.strict_encode64 final
  end

  def compute_key(key, hash)
    hash1 = sha1_hmac(key, hash)
    hash2 = sha1_hmac(key, "#{hash1}#{hash}")
    hash3 = sha1_hmac(key, hash1)
    hash4 = sha1_hmac(key, "#{hash3}#{hash}")

    "#{hash2}#{hash4[0 ... 4]}"
  end

  def sha1_hmac(data, key)
    Digest::HMAC.digest(key, data, Digest::SHA1)
  end
end