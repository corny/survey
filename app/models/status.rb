require 'socket'

module Status

  PATH     = Rails.root.join("tmp/sockets/policy.sock")
  COMMANDS = %w( status cache-mx cache-hosts )

  extend self

  def command(cmd)
    raise ArgumentError, "invalid command: #{cmd}" unless COMMANDS.include?(cmd)

    sock = UNIXSocket.new(PATH.to_s)
    sock.write cmd
    sock.close_write
    JSON.parse sock.read
  end

end