require 'rails_helper'
require 'zgrab'

describe Zgrab do

  subject{ Zgrab::Result.new JSON.parse(Rails.root.join("spec/fixtures/#{fixture}.json").read) }

  # echo 109.69.71.161 | ./zgrab --port 25 --smtp --starttls --banners tlsscan | head -n1 > spec/fixtures/valid.json
  context 'valid' do
    let(:fixture){ 'valid' }
    its(:starttls?){ should == true }
    its(:tls_version){ should == 'TLSv1.2' }
    its(:tls_cipher_suite){ should == 'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256' }
    its(:names){ should == %w( mail.digineo.de digineo.de ) }
    its(:certificate_valid?){ should == true }
    its(:self_signed?){ should == false }
    it do
      expect(subject.certificates.first.subject.to_a.select{|e| e[0]=='CN'}).to eq [["CN", "mail.digineo.de", 19]]
    end
  end

  context 'no starttls' do
    let(:fixture){ 'no-starttls' }
    its(:tls_version){ should == nil }
    its(:tls_cipher_suite){ should == nil }
    its(:starttls?){ should == false }
    its(:certificate_valid?){ should == nil }
    its(:self_signed?){ should == nil }
  end

  context 'timeout' do
    let(:fixture){ 'timeout' }
    its(:starttls?){ should == nil }
    its(:certificate_valid?){ should == nil }
    its(:self_signed?){ should == nil }
    its(:error){ should == "read: i/o timeout" }
  end

  context 'negative_serial' do
    let(:fixture){ 'negative_serial' }
    its(:starttls?){ should == true }
    its(:certificate_valid?){ should == nil }
    its(:self_signed?){ should == nil }
    its("certificates.count"){ should == 1 }
    its(:error){ should include "negative serial number" }
  end

end