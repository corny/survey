module Zgrab

  class Result
    def initialize(data)
      @data = data
    end

    def host
      @data['host']
    end

    def domain
      @data['domain']
    end

    def time
      @data['time']
    end

    def log(type)
      @data['log'].find{|l| l['type'] == type }
    end

    def server_certificates(*args)
      fetch log('tls_handshake'), 'data', 'server_certificates', *args
    end

    def starttls?
      l = log('starttls')
      l && l['error'].nil?
    end

    def certificates
      server_certificates('certificates').try :map do |cert|
        OpenSSL::X509::Certificate.new Base64.decode64(cert)
      end
    end

    def parsed_certificate(*args)
      fetch server_certificates, 'parsed', *args
    end

    def signature(*args)
      parsed_certificate 'signature', *args
    end

    def certificate_valid?
      signature 'valid'
    end

    def self_signed?
      signature 'self_signed'
    end

    def names
      fetch server_certificates, 'parsed', 'certificate', 'extensions', 'subject_alt_name', 'dns_names'
    end

    protected

    def fetch(h, *args)
      while (key = args.shift) && h
        h = h[key]
      end
      h
    end

  end

end
