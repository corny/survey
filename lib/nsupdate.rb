class NsUpdate

  class Error < ::StandardError; end

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
    @count  = 0
    @lines  = "server #{SERVER}\n"
    @lines << "zone #{ZONE}\n"
  end

  # Adds a delete and update
  def update(subdomain, data)
    domain = [subdomain, ZONE].join(".")

    @lines << "update delete #{domain} TXT\n"
    @lines << "update add #{domain} #{TTL} TXT \"#{data}\"\n"
    @count += 1

    self
  end

  def execute
    ms = Benchmark.ms do
      self.class.nsupdate @lines
    end
    Rails.logger.info 'nsupdate to %s with %i updates (%.1fms)' % [ SERVER, @count, ms ]
  end

  def self.key
    Rails.root.join("data").children.find{|c| c.to_s.ends_with?(".private") } || (raise "key not found")
  end

  # Executes nsupdate
  def self.nsupdate(input)
    cmd = ["nsupdate", "-k", key.to_s]
    out = IO.popen(cmd, "r+", err: [:child, :out]){ |io|
      io << input
      io << "send\n"
      io.close_write
      io.read
    }
    if $?.to_i != 0
      raise Error, "#{cmd.inspect} failed: #{out}"
    end
  end

end
