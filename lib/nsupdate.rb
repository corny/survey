class NsUpdate

  SERVER = "127.0.0.1"
  ZONE   = 'tls-scan.informatik.uni-bremen.de'
  TTL    = 3600

  # Single update
  def self.update(*args)
    new.update(*args).execute
  end

  # Multiple updates in a given block
  def self.execute
    instance = NsUpdate.new
    yield instance
    instance.execute
  end

  def initialize
    @lines  = "server #{SERVER}\n"
    @lines << "zone #{ZONE}\n"
  end

  def update(subdomain, data)
    domain = [subdomain, ZONE].join(".")

    @lines << "update delete #{domain} TXT\n"
    @lines << "update add #{domain} #{TTL} TXT \"#{data}\"\n"

    self
  end

  def execute
    @lines << "send\n"
    self.class.nsupdate @lines
  end

  def self.key
    Rails.root.join("data").children.find{|c| c.to_s.ends_with?(".private") } || (raise "key not found")
  end

  def self.nsupdate(input)
    puts input

    cmd = ["nsupdate", "-k", key.to_s]
    out = IO.popen(cmd, "r+", err: [:child, :out]){ |io|
      io << input
      io.close_write
      io.read
    }
    if $?.to_i != 0
      raise "#{cmd.inspect} failed: #{out}"
    end
  end

end
