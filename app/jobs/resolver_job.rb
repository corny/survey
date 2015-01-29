class ResolverJob < ActiveJob::Base
  queue_as :default

  def perform(record, method)
    record.send method
  end

end
