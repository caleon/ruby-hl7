module HL7Helpers
  def self.extended(klass)
    klass.send(:include, self)
  end

  def tmp_path
    File.expand_path('./spec/tmp')
  end

  def root_path
    File.expand_path('./test_data/pdfs')
  end

  def tmp_hl7(name)
    hl7(name, tmp_path)
  end

  def hl7(name, dir = nil)
    File.join(dir || root_path, "#{name}.hl7")
  end
end

def write_hl7_composite_files!
  if example.metadata[:segment]#, *example.metadata[:others]
    segment_keys  << [example.metadata[:segment],
                      example.metadata[:variant]].compact.join.to_sym
  end

  File.exists?(test_hl7) or File.open(test_hl7,
    'w') { |f| f.puts ordered_keys.map { |p| IO.read hl7(names[p]) }.compact }
  @raw_data = open(test_hl7).readlines
  @message = described_class.new(@raw_data)
end

shared_context 'proper configuration', :configured do
  let(:message) { @message }
  subject       { @message }

  describe '[Setup]' do
    it 'dynamically wrote a composite HL7 file' do
      test_hl7.should match /[-a-z0-9]{3,}\.hl7$/
      File.should exist test_hl7
    end

    it 'wrote a file containing validly parse-able blob' do
      @raw_data.should_not be_nil
      @raw_data.should be_a_kind_of Enumerable
    end
  end
end

shared_examples_for 'a properly parsed Message', :composite do

  it { should_not be_nil }
  it { should have_at_least(5).segments }

  [:MSH, :PID, :PV1, :ORC, :OBR].each do |type|
    it_should_behave_like 'a Message containing Segment of type', type

    # describe "The #{type} Segment", :segment => type do
    # end
  end
end

shared_examples_for 'a Message containing Segment of type' do |type|
  let(:segment_type) { type || example.metadata[:segment] }

  describe(type || 'that is expected') do
    let(:segments_by_name) { message.instance_variable_get(:@segments_by_name) }

    it 'should have an instance variable @segments_by_name' do
      segments_by_name.should_not be_nil
      segments_by_name.should_not be_empty
    end

    it "includes in its segments_by_name variable at least one entry" do
      segments_by_name[segment_type].should_not be_nil
      segments_by_name[segment_type].should_not be_empty
      segments_by_name[segment_type].should have_at_least(1).entry
    end
  end
end

shared_context 'Segment object', :segment do # doesn't get called if the val is not just a true.
  before(:each) { puts "WOOHOO!!!!!!!!! I GOT TRIGGERED!" }
end

shared_examples_for 'a proper Segment' do

end

[:MSH, :PID, :PV1, :ORC, :OBR, :OBX, :ZEF, :ZPS].each do |type|
  shared_context "setup for #{type} Segments", :segment => type do
    let(:segments) { Array[*message[type]] }
    let(:segment) { segments[0] }
  end

  shared_examples_for "#{type} Segments", :segment => type do
    specify { segment.should be_a_kind_of HL7::Message::Segment.const_get(type) }
  end
end

shared_examples_for 'OBX Segments within a proper Message', :segment => :OBX do
  it_should_behave_like 'a Message containing Segment of type', :OBX

  describe 'an OBX', 'regardless of directly embedding or attaching on ZEFs' do
    subject { segment }

    it { should respond_to :children }
    its(:children) { should_not be_nil }

    # it 'should be designated with @is_child = true' do
    #   segment.instance_variable_get(:@is_child).should be_true
    # end

    # it 'should be designated with @is_child_segment = true' do
    #   segment.instance_variable_get(:@is_child_segment).should be_true
    # end

    it 'should accompany an OBR element in the same message' do
      message[:OBR].should_not be_nil
      message[:OBR].should be_a HL7::Message::Segment::OBR
    end

    # it 'should have an OBR as its @parental' do
    #   segment.instance_variable_get(:@parental).should == message[:OBR]
    # end

    # its(:segment_parent) { should == message[:OBR] }
  end
end

shared_examples_for 'ZEF Segments with embedded data', :segment => :ZEF do
  describe 'a ZEF' do
    subject { segment }

    its(:set_id) { should == '1' }
    its(:embedded_pdf) { should_not be_nil }
    its(:embedded_pdf) { should_not be_empty }
    # its(:segment_parent) { should == parent_obx }
  end
end
