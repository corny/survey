require 'rails_helper'

describe RawCertificate do

  let(:x509){ OpenSSL::X509::Certificate.new file.read }
  let(:file){ Rails.root.join "spec/fixtures/x509/#{filename}.pem" }
  subject{ RawCertificate.find_or_create x509 }

  context 'rsa2048' do
    let(:filename){ "rsa2048" }
    its(:key_size){ should == 2048 }
    its(:key_type){ should == "RSA" }
    its("names.size"){ should == 20 }
    it{ expect(subject.names).to include *%w( mx.google.com aspmx.l.google.com ) }
    it{ expect(subject.valid_for_name? "mx.google.com").to eq true }
    it{ expect(subject.valid_for_name? "foo.google.com").to eq false }
  end

  context 'dsa' do
    let(:filename){ "dsa" }
    its(:key_size){ should == 1024 }
    its(:key_type){ should == "DSA" }
    its(:names){ should == ['protein.sk'] }
    it{ expect(subject.valid_for_name? "protein.sk").to eq true }
    it{ expect(subject.valid_for_name? "www.protein.sk").to eq false }
    it{ expect(subject.valid_for_name? "sk").to eq false }
  end

  context 'ec' do
    let(:filename){ "ec" }
    its(:key_size){ should == 384 }
    its(:key_type){ should == "EC" }
  end

end