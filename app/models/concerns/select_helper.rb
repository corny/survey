module SelectHelper
  extend ActiveSupport::Concern

  module ClassMethods
    def select_with_group(*fields)
      select("COUNT(*) as count, " << fields.join(","))
      .group(*fields)
      .map do |row|
        attributes = row.attributes
        attributes.delete('id')
        attributes
      end
    end
  end

end