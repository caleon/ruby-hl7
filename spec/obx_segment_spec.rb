# encoding: UTF-8
$: << '../lib'
require 'ruby-hl7'

describe HL7::Message::Segment::OBX do
  before :all do
    @base = "OBX||TX|FIND^FINDINGS^L|1|This is a test on 05/02/94."
  end

  context 'general' do
    it 'allows access to an OBX segment' do
      obx = HL7::Message::Segment::OBX.new @base
      obx.set_id.should == ""
      obx.value_type.should == "TX"
      obx.observation_id.should == "FIND^FINDINGS^L"
      obx.observation_sub_id.should == "1"
      obx.observation_value.should == "This is a test on 05/02/94."
    end

    it 'allows creation of an OBX segment' do
      lambda do
        obx = HL7::Message::Segment::OBX.new
        obx.value_type = "TESTIES"
        obx.observation_id = "HR"
        obx.observation_sub_id = "2"
        obx.observation_value = "SOMETHING HAPPENned"
      end.should_not raise_error
    end
  end

end
