require 'rails_helper'
require 'zgrab'

describe Zgrab do

  subject{ Zgrab::Result.new JSON.parse(Rails.root.join("spec/fixtures/#{fixture}.json").read) }

  context 'valid' do
    let(:fixture){ 'valid' }
    its(:starttls?){ should == true }
    its(:names){ should == %w( mail.digineo.de digineo.de ) }
    its(:certificate_valid?){ should == true }
    its(:self_signed?){ should == false }
    it do
      expect(subject.certificates.first.subject.to_a.select{|e| e[0]=='CN'}).to eq [["CN", "mail.digineo.de", 19]]
    end
  end
  
  context 'hostname mismatch' do
    let(:fixture){ 'hostname-mismatch'}
    its(:starttls?){ should == true }
    its(:names){ should == %w( *.ispgateway.de ispgateway.de ) }
    its(:certificate_valid?){ should == false }
    its(:self_signed?){ should == false }
  end

  context 'no starttls' do
    let(:fixture){ 'no-starttls' }
    its(:starttls?){ should == false }
    its(:certificate_valid?){ should == nil }
    its(:self_signed?){ should == nil }
  end

  context 'timeout' do
    let(:fixture){ 'timeout' }
    its(:starttls?){ should == nil }
    its(:certificate_valid?){ should == nil }
    its(:self_signed?){ should == nil }
  end

end