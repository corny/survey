namespace :iana do
  desc "Displays IANA cipher suites"
  task :cipher_suites do
    require 'net/https'
    require 'rexml/document'
    require 'byebug'

    res = Net::HTTP.get_response URI.parse('https://www.iana.org/assignments/tls-parameters/tls-parameters.xml')
    res.error! unless res.is_a?(Net::HTTPOK)


    doc = REXML::Document.new(res.body)
    REXML::XPath.each(doc, "registry/registry[@id='tls-parameters-4']/record") do |record|
      h    = Hash[record.elements.map{|e| [e.name, e.text] }]
      name = h['description']
      if name =~ /^TLS_/
        hex = "0x" << h['value'].scan(/0x(\h\h)/).join
        puts hex.to_i(16).to_s << ": #{name}"
      end
    end

  end

end
