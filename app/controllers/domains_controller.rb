class DomainsController < ApplicationController

  def show
    @domain = Domain.where(name: params[:id]).first!
  end

end
