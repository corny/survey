class DomainSummary

  def initialize(domain)
    @domain = domain
  end

  # STARTTLS status
  def starttls
    # all hosts must support STARTTLS
    mx_records.try :all?, &:starttls
  end

  # certificate status
  def certificate
    records = mx_records
    return unless records

    results = []
    results << (records.all?(&:cert_valid) ? "trusted" : "untrusted")
    results << "match-mx"     if records.all?(&:cert_matches)
    results << "match-domain" if records.all?{|r| r.valid_for_name? @domain.name }
    results
  end

  def to_s
    case starttls
    when nil
      "starttls=unknown"

    when false
      "starttls=false"

    when true
      result = "starttls=true"
      if cert = certificate
        result << " certificate=" << certificate.try(:join, ',')
      end
      result

    else
      raise ArgumentError
    end
  end

  protected

  # MX records with reachable hosts
  def mx_records
    return @mx_records if instance_variable_defined?("@mx_records")
    @mx_records = MxRecord.where("hostname IN (?)", @domain.mx_hosts).joins(:mx_host).where("starttls IS NOT NULL")
    @mx_records = nil if @mx_records.empty?
    @mx_records
  end

end
