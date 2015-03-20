require 'rails_helper'
require 'certificate_builder'

describe DomainSummary do

  subject { DomainSummary.new(domain) }

  let(:domain){ create :domain, mx_hosts: mx_hosts }
  let(:mx_hosts){ [name_a,name_b].compact }

  # STARTTLS support
  let(:starttls_a){ nil }
  let(:starttls_b){ nil }

  # MX Names
  let(:name_a){ "mx.example.com" }
  let(:name_b){ "mail.foobar.org" }

  # MX Records
  let(:record_a){ create :mx_record, hostname: name_a, cert_matches: cert_matches_a }
  let(:record_b){ create :mx_record, hostname: name_b, cert_matches: cert_matches_b }

  # MX Hosts
  let!(:host_a){ create :mx_host, starttls: starttls_a, address: record_a.address, cert_valid: cert_valid_a, certificate: certificate_a }
  let!(:host_b){ create :mx_host, starttls: starttls_b, address: record_b.address, cert_valid: cert_valid_b, certificate: certificate_b }

  # Common Names
  let(:cn_a){ [name_a] }
  let(:cn_b){ [name_b] }

  let(:certificate_a){ RawCertificate.find_or_create(CertificateBuilder.build(cn_a)) }
  let(:certificate_b){ RawCertificate.find_or_create(CertificateBuilder.build(cn_b)) }
  let(:cert_matches_a){ cn_a.include?(name_a) }
  let(:cert_matches_b){ cn_b.include?(name_b) }
  let(:cert_valid_a){ nil }
  let(:cert_valid_b){ nil }

  context 'without records' do
    its(:starttls){ should == nil }
    its(:to_s){ should == "starttls=unknown" }
  end

  context 'unreachable' do
    before{ host_a }
    its(:starttls){ should == nil }
  end

  context 'with non-starttls records' do
    let(:starttls_a){ false }
    let(:starttls_b){ false }
    its(:starttls){ should == false }
    its(:to_s){ should == "starttls=false" }
  end

  context 'with mixed STARTTLS records' do
    let(:starttls_a){ true }
    let(:starttls_b){ false }
    its(:starttls){ should == false }
  end

  context 'with STARTTLS=true and unreachable' do
    let(:starttls_a){ true }
    let(:starttls_b){ nil }
    its(:starttls){ should == true }
  end

  context 'with only starttls records' do
    let(:starttls_a){ true }
    let(:starttls_b){ true }
    its(:starttls){ should == true }

    context 'invalid certificates' do
      let(:cert_valid_a){ false }
      let(:cert_valid_b){ false }
      its(:certificate){ should == ["invalid", "match-mx"] }
    end

    context 'only one matching mx' do
      let(:cert_matches_a){ true }
      let(:cert_matches_b){ false }
      its(:certificate){ should == ["invalid"] }
    end

    context 'not matching mx' do
      let(:cn_a){ ["xxx"] }
      its(:certificate){ should == ["invalid"] }
    end

    context 'valid certificates' do
      let(:cert_valid_a){ true }
      let(:cert_valid_b){ true }

      context 'one matching domain' do
        its(:certificate){ should == ["valid"] }
        let(:cn_a){ [domain.name] }
      end

      context 'both matching only domain' do
        let(:cn_a){ [domain.name] }
        let(:cn_b){ cn_a }
        its(:certificate){ should == ["valid", "match-domain"] }

        context 'and matching mx' do
          let(:cn_a){ [domain.name] + mx_hosts }
          its(:certificate){ should == ["valid", "match-mx", "match-domain"] }
        end
      end
    end

  end

end
