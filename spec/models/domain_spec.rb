require 'rails_helper'

describe Domain do

  describe 'empty mx' do
    subject { Domain.new mx_hosts: [] }
    its(:valid_mx?){   should == false }
    its(:invalid_mx?){ should == false }
  end

  describe 'valid mx' do
    subject { Domain.new mx_hosts: %w( mx.example.com foo.co.uk ) }
    its(:valid_mx?){   should == true }
    its(:invalid_mx?){ should == false }
  end

  describe 'invalid mx' do
    subject { Domain.new mx_hosts: %w( 1.2.3.4 xx ) }
    its(:valid_mx?){   should == false }
    its(:invalid_mx?){ should == true }
  end

  describe 'mixed mx' do
    subject { Domain.new mx_hosts: %w( mx.example.com xx ) }
    its(:valid_mx?){   should == true }
    its(:invalid_mx?){ should == true }
  end

end
