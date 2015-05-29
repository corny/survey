module Vars

  extend self

  def to_h
    {
      hosts:        hosts,
      certificates: certificates,
    }
  end

  def hosts
    h = {
      total:    MxHost.count,
      starttls: MxHost.where(starttls: true).count,
    }
    h[:starttls_percent] = h[:starttls].to_f / h[:total] * 100
    h
  end

  def certificates
    {
      total: Certificate.count,
      validity: {
        below_zero: Certificate.where("days_valid < 0").count
      }
    }
  end

end
