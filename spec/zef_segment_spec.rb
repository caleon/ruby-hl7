# encoding: UTF-8
$: << '../lib'
require 'ruby-hl7'

describe HL7::Message::Segment::ZEF do
  context 'general' do
    before :all do
      @base_zef = open('./test_data/pdfs/zef.hl7').readlines.first
    end

    it 'creates a ZEF segment' do
      lambda do
        zef = HL7::Message::Segment::ZEF.new( @base_zef )
        zef.should_not be_nil
        zef.to_s.should == @base_zef
      end.should_not raise_error
    end

    it 'allows access to an ZEF segment' do
      lambda do
        zef = HL7::Message::Segment::ZEF.new( @base_zef )
        zef.set_id.should == '1'
        zef.embedded_pdf[0, 6].should == 'JVBERi'
        zef.embedded_pdf[-6, 6].should == '9GCg=='
      end.should_not raise_error
    end

  end
end
