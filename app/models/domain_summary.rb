class DomainSummary

  def initialize(domain)
    @domain = domain
  end

  def starttls
    mx_hosts.try :all?, &:starttls
  end

  def to_s
    "starttls=#{starttls}"
  end

  protected

  def mx_hosts
    mx_names = @domain.mx_hosts
    return if mx_names.blank?

    MxHost.where("address IN (SELECT address FROM mx_records WHERE hostname IN (?))", mx_names)
  end

end
