class MxHostsController < ApplicationController

  def index
    @entries = MxHost.limit(250)
  end

end
