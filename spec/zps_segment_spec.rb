# encoding: UTF-8
$: << '../lib'
require 'ruby-hl7'

describe HL7::Message::Segment::ZPS do
  context 'general' do
    before :all do
      @base_zps = open('./test_data/pdfs/zps.hl7').readlines.first
    end

    it 'creates a ZPS segment' do
      lambda do
        zps = HL7::Message::Segment::ZPS.new( @base_zps )
        zps.should_not be_nil
        zps.to_s.should == @base_zps
      end.should_not raise_error
    end

    it 'allows access to an ZPS segment' do
      lambda do
        zps = HL7::Message::Segment::ZPS.new( @base_zps )
        zps.set_id.should == '1'
        zps.facility_footnote_code.should == '-8'
        zps.facility_name.should == 'Oklahoma City'
        zps.facility_address.should == '840 Research Parkway^^Oklahoma City^OK^73104'
        zps.facility_phone_number.should == '4055551212'
        zps.facility_contact.should == 'contact'
        zps.facility_director.should == "M.D.^O'DOWD^G.^J^^^M.D."
        zps.facility_lab_code.should == 'mnemo'
        zps.facility_clia_number.should == '42'
      end.should_not raise_error
    end

  end
end
