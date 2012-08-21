# encoding: UTF-8

shared_context 'Message instance', :message do
  let(:message) { @message }
  subject { @message }
end


shared_examples_for 'a properly parsed Message' do
  subject { message }

  it { should_not be_nil }
  it { should be_a_kind_of HL7::Message }
  it { should have_at_least(5).segments }

  [:MSH, :PID, :PV1, :ORC, :OBR].each do |type|
    it_behaves_like 'a Message containing Segment of type', type
  end
end


shared_examples_for 'a Message containing Segment of type' do |type| # IS THE NIL CASE NECESSARY?

  describe(type || 'that is expected') do
    let(:segments_by_name) { message.instance_variable_get(:@segments_by_name) }

    it 'should have an instance variable @segments_by_name' do
      segments_by_name.should_not be_nil
      segments_by_name.should_not be_empty
      segments_by_name.should be_a_kind_of Hash
    end

    it "includes in its segments_by_name variable at least one entry" do
      segments_by_name[type].should_not be_nil
      segments_by_name[type].should_not be_empty
      segments_by_name[type].should have_at_least(1).entry
    end
  end
end


[:MSH, :PID, :PV1, :ORC, :OBR, :OBX, :ZEF, :ZPS].each do |type|
  shared_context "Setup for #{type} Segments", :type => type do
    let(:segments) { Array[*message[example.metadata[:type]]] }
    let(:segment) { segments[0] }
  end

  shared_context "Setup subject as #{type} Segment", :segment, :type => type do
    subject { segment }
  end

  shared_examples_for "#{type} Segments", :segment, :type => type do
    it { should be_a_kind_of HL7::Message::Segment.const_get(example.metadata[:type]) }
  end
end


shared_examples_for 'OBX Segments within a proper Message', :type => :OBX do
  it_behaves_like 'a Message containing Segment of type', :OBX

  describe 'OBX', 'regardless of directly embedding or attaching on ZEFs', :segment do
    it 'should be designated with @is_child_segment = true' do
      segment.instance_variable_get(:@is_child_segment).should be_true
    end

    it { should be_is_child_segment }
    it { should respond_to :children }
    its(:children) { should_not be_nil }
    its(:segment_parent) { should satisfy { |x| x == message[:OBR] } }
  end
end


shared_examples_for 'ZEFs in their general form' do
  it 'should be designated with @is_child_segment = true' do
    segment.instance_variable_get(:@is_child_segment).should be_true
  end

  it { should be_is_child_segment }
  it { should_not respond_to :children }
  its(:segment_parent) { should satisfy { |x| x == message[:OBX] } }
end


shared_examples_for 'ZEF Segments within a proper Message', :type => :ZEF do
  it_behaves_like 'a Message containing Segment of type', :ZEF
  it_behaves_like 'ZEFs in their general form'
end


shared_examples_for 'ZEF Segments w/ embedded data' do
  it_behaves_like 'ZEF Segments within a proper Message'

  its(:set_id) { should == expected_set_id }
  its(:embedded_pdf) { should_not be_nil; should_not be_empty }
  its(:segment_parent) { should == expected_parent }
end


shared_examples_for 'proper OBR -> OBX associations' do
  subject { obr }

  it { should be_a_kind_of HL7::Message::Segment::OBR }
  it { should respond_to :children }
  its(:children) { should be_a_kind_of Array }
  its(:children) { should respond_to :old_append }
  its(:children) { should include obx }
  it { should == obx.segment_parent }
  its(:children) { should satisfy { |x| x.instance_variable_get(:@parental) == obr } }
end


shared_examples_for 'child_types methods' do
  it { should_not be_nil }
  it { should be_a_kind_of Array }
  it { should_not be_empty }
  it { should =~ expected_children }
end

shared_context 'For checking associations rather than content', :message, :segment do
  let(:obr) { message[:OBR] }
  let(:obx) { message[:OBX] }
  let(:zef) { message[:ZEF] }
end

