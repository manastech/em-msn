module Msn::Protocol
  include EventMachine::Protocols::LineText2

  def post_init
    @trid = 0
    @command_fibers = {}
  end

  def receive_line(line)
    puts "<< #{line}" if Msn::Messenger.debug
    pieces = line.split(' ')

    case pieces[0]
    when 'CHL'
      answer_challenge pieces[2]
    when 'RNG'
      handle_event pieces
    when 'MSG'
      @header = pieces

      size = pieces.last.to_i
      set_binary_mode size
    when 'QRY'
      # ignore
    else
      if fiber = @command_fibers.delete(pieces[1].to_i)
        fiber.resume pieces
      else
        handle_event pieces
      end
    end
  end

  def receive_binary_data(data)
    puts "<<* #{data}" if Msn::Messenger.debug

    handle_event @header, data
  end

  def handle_event(header, data = nil)
    return unless @event_handlers

    handler = @event_handlers[header[0]]
    if handler
      Fiber.new do
        handler.call header, data
      end.resume
    end
  end

  def answer_challenge(challenge_string)
    payload = Digest::MD5.hexdigest "#{challenge_string}Q1P7W2E4J9R8U3S5"

    data = "QRY #{@trid} msmsgs@msnmsgr.com 32\r\n#{payload}"
    puts ">>* #{data}" if Msn::Messenger.debug

    send_data data

    @trid += 1
  end

  def send_command(command, *args)
    @command_fibers[@trid] = Fiber.current

    text = "#{command} #{@trid} #{args.join ' '}\r\n"
    puts ">> #{text}" if Msn::Messenger.debug
    send_data text
    @trid += 1

    Fiber.yield
  end

  def on_event(kind, &block)
    @event_handlers ||= {}
    @event_handlers[kind] = block
  end

  def clear_event(kind)
    @event_handlers.delete kind
  end

  def method_missing(name, *args)
    send_command name.upcase, *args
  end

  def unbind
    puts "Chau :-("
  end
end

