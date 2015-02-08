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

OpenSSL::X509::Certificate.include OpensslExtensions::Fingerprint
OpenSSL::X509::Request.include     OpensslExtensions::Fingerprint
OpenSSL::PKey::PKey.include        OpensslExtensions::Fingerprint
