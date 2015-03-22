module NsUpdate
  extend self

  SERVER = "127.0.0.1"
  ZONE   = 'tls-scan.informatik.uni-bremen.de'
  TTL    = 3600

  def update(subdomain, data)
    update = []
    domain = [subdomain, ZONE].join(".")

    update << "server #{SERVER}"
    update << "zone #{ZONE}"
    update << "update delete #{domain} TXT"
    update << "update add #{domain} #{TTL} TXT \"#{data}\""
    update << "send"

    nsupdate update.join("\n")
  end

  protected

  def key
    Rails.root.join("data").children.find{|c| c.to_s.ends_with?(".private") } || (raise "key not found")
  end

  def nsupdate(input)
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
