module SelectHelper
  extend ActiveSupport::Concern

  module ClassMethods
    def select_with_group(*fields)
      if fields.size==1 && Hash === fields[0]
        select = fields[0].map{|k,v| "(#{v}) AS #{k}" }
        keys   = fields[0].keys.map(&:to_s)
      else
        select = fields
        keys   = fields
      end

      select("COUNT(*) as count, " << select.join(","))
      .group(*keys)
      .order(*keys)
      .map do |row|
        attributes = row.attributes
        attributes.delete('id')
        attributes
      end
    end
  end

end
