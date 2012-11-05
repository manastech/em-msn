module Msn::Protocol
  include EventMachine::Protocols::LineText2

  def post_init
    @trid = 1
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
    when 'MSG', 'NOT', 'GCF', 'UBX'
      handle_payload_command pieces
    when 'QRY'
      # ignore
    when 'ADL', 'RML'
      if pieces[2] == 'OK'
        handle_normal_command pieces
      else
        handle_payload_command pieces
      end
    else
      handle_normal_command pieces
    end
  end

  def handle_normal_command(pieces)
    if fiber = @command_fibers.delete(pieces[1].to_i)
      fiber.resume pieces
    else
      handle_event pieces
    end
  end

  def handle_payload_command(pieces)
    @header = pieces

    size = pieces.last.to_i
    set_binary_mode size
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
    send_payload_command "QRY", Msn::Challenge::ProductId, Msn::Challenge.challenge(challenge_string)
  end

  def send_command(command, *args)
    @command_fibers[@trid] = Fiber.current

    text = "#{command} #{@trid} #{args.join ' '}\r\n"
    send_command_internal text

    Fiber.yield
  end

  def send_payload_command(command, *args)
    payload = args.pop
    args.push payload.length
    send_command_internal "#{command} #{@trid} #{args.join ' '}\r\n#{payload}"
  end

  def send_payload_command_and_wait(command, *args)
    @command_fibers[@trid] = Fiber.current

    send_payload_command command, *args

    Fiber.yield
  end

  def send_command_internal(text)
    puts ">> #{text}" if Msn::Messenger.debug
    send_data text
    @trid += 1
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
end

