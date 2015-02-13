require 'rails_helper'

describe RawCertificate do

  let(:x509){ OpenSSL::X509::Certificate.new file.read }
  let(:file){ Rails.root.join "spec/fixtures/x509/#{filename}.pem" }
  subject{ RawCertificate.find_or_create x509 }

  context 'rsa2048' do
    let(:filename){ "rsa2048" }
    its(:key_size){ should == 2048 }
    its(:key_type){ should == "RSA" }
  end

  context 'dsa' do
    let(:filename){ "dsa" }
    its(:key_size){ should == 1024 }
    its(:key_type){ should == "DSA" }
  end

  context 'ec' do
    let(:filename){ "ec" }
    its(:key_size){ should == 384 }
    its(:key_type){ should == "EC" }
  end

end