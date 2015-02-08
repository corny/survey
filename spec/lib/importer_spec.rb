require 'rails_helper'
require 'importer'

describe Importer do

  before { Importer.import JSON.parse(Rails.root.join("spec/fixtures/#{fixture}.json").read) }

  context 'valid' do
    let(:fixture){ 'valid' }
    it do
      expect(RawCertificate.count).to eq 2
    end
  end

  context 'no starttls' do
    let(:fixture){ 'no-starttls' }
    it do
      expect(RawCertificate.count).to eq 0
    end
  end
  
end