require 'rails_helper'

describe DomainsController do

  context "get show" do
    it "with existing domain" do
      get 'show', id: create(:domain).name
      response.should be_success
    end

    it "with non-existing domain" do
      expect { get 'show', id: "foo" }.to \
        raise_error ActiveRecord::RecordNotFound
    end
  end

end
