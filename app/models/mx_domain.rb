class MxDomain < ActiveRecord::Base

  has_many :mx_records,
    foreign_key: :hostname,
    primary_key: :name

end
