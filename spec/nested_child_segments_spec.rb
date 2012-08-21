# encoding: UTF-8
$: << '../lib'
require 'ruby-hl7'

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.filter_run_excluding :broken => true

  require File.expand_path('../support/hl7_helpers', __FILE__)
  # require File.expand_path('../support/hl7_shared_examples', __FILE__)
  c.extend HL7Helpers

  c.before(:all,  :composite_tests) do
    FileUtils.remove_dir tmp_path if File.exists?(tmp_path)
    FileUtils.mkdir_p    tmp_path
  end
end

describe 'nesting and children' do
  before :all do
    @base = "OBX||TX|FIND^FINDINGS^L|1|This is a test on 05/02/94."
  end

  EXPECTED_CHILDREN = [:NTE, :ZEF, :ZPS]
  let(:expected_children) { EXPECTED_CHILDREN }
  let(:segment) { HL7::Message::Segment::OBX.new @base }
  subject { segment }

  it { should respond_to :segment_parent }
  describe '#segment_parent' do
    its(:segment_parent) { should be_nil }
  end

  it 'should have an initialized @is_child_segment of false' do
    segment.instance_variable_defined?(:@is_child_segment).should be_true
    segment.instance_variable_get(:@is_child_segment).should be_false
  end

  its(:class) { should respond_to :child_types }
  describe '.child_types' do
    subject { segment.class.child_types }
    it { should_not be_nil }
    it { should be_a_kind_of Array }
    it { should_not be_empty }
    it { should =~ expected_children }
  end

  it { should respond_to :child_types }
  describe '#child_types' do
    subject { segment.child_types }
    it { should_not be_nil }
    it { should be_a_kind_of Array }
    it { should_not be_empty }
    it { should =~ expected_children }
  end

  its(:child_types) { should == segment.class.child_types }

  it { should respond_to :children }
  describe '#children' do
    subject { segment.children }

    it { should_not be_nil }
    it { should be_a_kind_of Array }

    it 'should use the @my_children ivar' do
      subject.should == segment.instance_variable_get(:@my_children)
    end

    it 'should store a @parental ivar' do
      subject.instance_variable_get(:@parental).should == segment
      segment.instance_variable_defined?(:@parental).should be_false
    end

    it { should respond_to :<< }
    it { should respond_to :old_append }

    describe '#<<' do
      let(:zef_io) { open('./test_data/pdfs/zef.hl7').readlines }
      let(:zef0) { HL7::Message::Segment::ZEF.new zef_io }

      before do
        zef0.should be_a_kind_of HL7::Message::Segment::ZEF
        segment.children.should_not include zef0
        # subject.should_not include zef0
      end

      it 'should not accept nil as param' do
        lambda { subject << nil }.should raise_error HL7::Exception
      end

      it "should set the segment_parent of the appended segment" do
        lambda { subject << zef0 }.should_not raise_error
        subject.should include zef0
        segment.children.should include zef0
      end

      context 'when the child being appended happens deeper than one level down',
                                             :composite_tests,# :alternate_parse,
                                             :segment => :OBX, :variant => :a do
        # include_context 'My intended method of parsing'
        before(:all) do
          File.open(test_hl7_file, 'w') do |f|
            f.puts ['msh-common', 'obx-attaching'].map { |p| IO.read hl7_file(p) }.compact
          end
          @message = my_parse_with(test_hl7_file)
        end

        let(:test_hl7_file) { tmp_hl7_file('nc-msh-common-obx-attaching') }
        let(:message) { @message }
        let(:obr) { message[:OBR] }
        let(:obx) { message[:OBX] }
        let(:zef) { HL7::Message::Segment::ZEF.new zef_io }

        it 'should first have setup the OBR -> OBX association properly' do
          obr.should be_a_kind_of HL7::Message::Segment::OBR
          obr.should respond_to :children
          obr.children.should be_a_kind_of Array
          obr.children.should respond_to :old_append
          obr.children.should include obx
          obx.segment_parent.should == obr
          obx.is_child_segment?.should be_true
          obr.children.instance_variable_get(:@parental).should == obr
        end

        it 'should not initially have an OBX -> ZEF association' do
          obx.children.should be_empty
          obx.accepts?(:ZEF).should be_true
        end

        it 'should properly append to the OBR -> OBX -> ZEF chain' do
          old_children = obr.children.dup

          obx.children << zef
          obx.children.should_not be_empty
          obx.children.should include(zef)
          zef.segment_parent.should == obx
          obx.children.instance_variable_get(:@parental).should == obx

          obr.children.should == old_children
          message.to_s.should include(zef.to_s)
        end
      end


      context 'when the child being appended happens deeper than one level down from the get-go',
                                             :composite_tests,# :alternate_parse,
                                             :segment => :OBX, :variant => :a do
        # include_context 'My intended method of parsing'
        before(:all) do

          File.open(test_hl7_file, 'w') do |f|
            f.puts ['msh-common', 'obx-attaching', 'zef'].map { |p| IO.read hl7_file(p) }.compact
          end
          @message = my_parse_with(test_hl7_file)
        end

        let(:test_hl7_file) { tmp_hl7_file('nc-msh-common-obx-attaching-zef') }
        let(:message) { @message }
        let(:obr) { message[:OBR] }
        let(:obx) { message[:OBX] }
        let(:zef) { message[:ZEF] }

        it 'should have properly parsed for the @segments ivar' do
          segs = message.instance_variable_get(:@segments)
          segs.should have(7).segments
        end

        it 'should have an expected @segments_by_name' do
          segs_by_name = message.instance_variable_get(:@segments_by_name)
          segs_by_name.should be_a_kind_of Hash
          segs_by_name.should have(7).items
          %w(MSH PID PV1 ORC OBR OBX ZEF).each do |name|
            segs_by_name[name.to_sym].each do |seg|
              seg.should be_a_kind_of HL7::Message::Segment
            end
          end
        end

        it 'should first have setup the OBR -> OBX association properly' do
          obr.should be_a_kind_of HL7::Message::Segment::OBR
          obr.should respond_to :children
          obr.children.should be_a_kind_of Array
          obr.children.should respond_to :old_append
          obr.children.should include obx
          obx.segment_parent.should == obr
          obr.children.instance_variable_get(:@parental).should == obr
        end

        it 'should have a zef element' do
          zef.should_not be_nil
          zef.should be_a_kind_of HL7::Message::Segment::ZEF
          zef.segment_parent.should == obx
          zef.instance_variable_get(:@is_child_segment).should be_true
          zef.is_child_segment?.should be_true
        end

        it 'should initially have an OBX -> ZEF association' do
          obx.accepts?(:ZEF).should be_true
          obx.children.should_not be_empty
          obx.children.should include zef
        end

      end

    end
  end

  it { should respond_to :accepts? }
  EXPECTED_CHILDREN.each do |child_type|
    it "should accept #{child_type}" do
      segment.accepts?(child_type).should be_true
    end
  end

  Dir.glob(File.join(File.expand_path('../../', __FILE__), 'lib/segments/*')).each do |fname|
    sym = File.basename(fname).gsub(/\.rb$/, '').upcase.to_sym
    unless EXPECTED_CHILDREN.include?(sym)
      it "should NOT accept #{sym}" do
        segment.accepts?(sym).should be_false
      end
    end
  end

end
