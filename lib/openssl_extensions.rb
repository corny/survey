module OpensslExtensions
  module Fingerprint

    %w( md5 sha1 sha256 sha512 ).each do |method|
      class_eval <<-EOF
        def #{method}(binary: false)
          if binary
            Digest::#{method.upcase}.digest(to_der)
          else
            Digest::#{method.upcase}.hexdigest(to_der)
          end
        end
      EOF
    end

  end
end

class OpenSSL::X509::Certificate

  def key_size
    key = public_key
    case key
    when OpenSSL::PKey::RSA
      key.n.num_bits
    when OpenSSL::PKey::DSA
      key.p.num_bits
    when OpenSSL::PKey::EC
      # don't know better
      public_key.to_text.match(%r((\d+) bit))[1].to_i
    end
  end

end

class OpenSSL::X509::Name
  def [](key)
    to_h[key]
  end

  def to_h
    @h ||= begin
      to_a.inject({}) do |memo,(k,v)|
        (memo[k] ||= []) << v if(k)
        memo
      end
    end
  end
end


OpenSSL::X509::Certificate.include OpensslExtensions::Fingerprint
OpenSSL::X509::Request.include     OpensslExtensions::Fingerprint
OpenSSL::PKey::PKey.include        OpensslExtensions::Fingerprint
