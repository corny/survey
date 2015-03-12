module RIPE

  extend self

  def reserved_network(addr)
    addr = IPAddr.new(addr) if addr.is_a?(String)
    reserved_addresses[addr.family].find{|net| net.include?(addr) }
  end

  def reserved_address?(addr)
    reserved_network(addr) != nil
  end

  def reserved_addresses
    @reserved_address ||= begin
      Rails.root.join("config/reserved_addresses.txt").read.each_line.map do |line|
        IPAddr.new(line.strip)
      end.group_by(&:family)
    end
  end

end
