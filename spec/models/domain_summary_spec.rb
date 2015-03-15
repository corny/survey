require 'rails_helper'

describe DomainSummary do

  subject { DomainSummary.new(domain) }

  context 'domain without records' do
    let(:domain){ create :domain }
    its(:starttls){ should == nil }
  end

  context 'domain with non-starttls records' do
    let(:domain){ create :domain, mx_hosts: [record.hostname] }
    let(:record){ create :mx_record }
    let!(:host){ MxHost.create! address: record.address }

    its(:starttls){ should == false }
  end

  context 'domain with only starttls records' do
    let(:domain){ create :domain, mx_hosts: [record.hostname] }
    let(:record){ create :mx_record }
    let!(:host){ MxHost.create! address: record.address, starttls: true }

    its(:starttls){ should == true }
  end


end
