module ICANN

  extend self

  HOST_PATTERN = /\A(xn--+)?[a-z0-9]+(-+[a-z0-9]+)*\z/

  def tlds
    @tlds ||= read_tlds
  end

  def fqdn_validity(name)
    errors = fqdn_errors(name)
    if errors.empty?
      :valid
    else
      ["invalid", *errors].join("_").to_sym
    end
  end

  def fqdn_errors(name)
    parts  = name.split(".")
    errors = []
    errors << :domain if     parts.empty? || parts.any?{|part| part !~ HOST_PATTERN }
    errors << :tld    unless valid_tld?(parts.last)
    errors
  end

  def fqdn?(name)
    fqdn_errors(name).empty?
  end

  def valid_tld?(tld)
    tlds.include? tld.to_s.downcase
  end

  def read_tlds
    result = Set.new
    Rails.root.join("config/tlds.txt").each_line do |line|
      result << line.strip.downcase unless line.start_with?("#")
    end
    result
  end

end