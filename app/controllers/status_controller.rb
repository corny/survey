class StatusController < ApplicationController

  def index
    @status      = Status.command("status")
    @cache_mx    = Status.command("cache-mx")
    @cache_hosts = Status.command("cache-hosts")
  rescue Errno::ECONNREFUSED
    @error = $!.message
    render :error, status: :service_unavailable
  end

end
