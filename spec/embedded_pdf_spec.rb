# encoding: UTF-8
$: << '../lib'
require 'ruby-hl7'

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  # c.filter_run_excluding :broken => true

  require File.expand_path('../support/hl7_helpers', __FILE__)
  require File.expand_path('../support/hl7_shared_examples', __FILE__)
  c.extend HL7Helpers

  c.before(:all,  :embedded_tests) do
    FileUtils.remove_dir tmp_path if File.exists?(tmp_path)
    FileUtils.mkdir_p    tmp_path
  end

  c.before(:each, :embedded_tests) do
    write_hl7_composite_files!
    @message = my_parse_with(test_hl7)
  end

  c.before(:each, :embedded_tests, :debug_hl7) do
    puts "(Using composite hl7: #{test_hl7})"
  end
end

describe HL7::Message, 'containing PDF data', :embedded_tests, :configured, :message do
  class HL7::Message
    def inspect
      vars = self.instance_variables.map{|v| "#{v}=.."}.join(", ")
      "<#{self.class}: #{vars}>"
    end
  end

  class HL7::Message::Segment
    def inspect
      vars = self.instance_variables.map{|v| "#{v}=.."}.join(", ")
      "<#{self.class}: #{vars}>"
    end
  end

  let!(:names_array) {
    [[:MSH  , 'msh-common'],
     [:NTE3 , 'nte-thrice'],
     [:OBX  , 'obx'],
     [:OBXa , 'obx-attaching'],
     [:OBXe , 'obx-embedding'],
     [:ZEF  , 'zef'],
     [:ZEF2 , 'zef-twice'],
     [:ZPS  , 'zps]']]
  }
  let!(:names) { Hash[names_array] }
  let(:segment_keys)  { [:MSH, *example.metadata[:others]] }
  let(:ordered_keys)  { segment_keys.compact.sort_by { |k| names_array.map(&:first).index(k) } }
  let(:output_name)   { ordered_keys.map { |k| names[k] } * '-' }
  let(:test_hl7)      { tmp_hl7(output_name) }

  it_should_behave_like 'a properly parsed Message'

  context 'when the PDF is embedded', 'on an OBX', :segment => :OBX do

    context 'directly', :variant => :e do
      describe 'OBX with the embedded data' do
        subject { segment }
        its(:children) { should be_empty }
        it 'should not have children ZEFs with embedded data' do
          segment.children.should_not be_any { |s| s.e0 == 'ZEF' }
        end
      end
    end

    context 'through its ZEFs', :variant => :a, :others => [:ZEF] do
      it_should_behave_like 'a Message containing Segment of type', :ZEF

      describe 'parent OBX of the ZEFs' do
        subject { segment }

        its(:children) { should_not be_empty }
        it 'should have children ZEFs with embedded data' do
          segment.children.should be_any { |s| s.e0 == 'ZEF' } # check data.
        end
      end

      describe 'ZEF with embedded data', :segment => :ZEF, :variant => nil,
                                                        :others => [:OBXa] do
        let(:parent_obx) { message[:OBX] }
        subject { segment }
        context 'on one Segment', :variant => nil do
          specify { segments.should have(1).segment }
          its(:embedded_pdf) { should match /^JVBER.+U9GCg==$/ }
        end

        context 'on two contiguous Segments', :variant => '2' do
          specify { segments.should have(2).segments }
          specify { segments[0].embedded_pdf.should match /^JVBER.+GwjBg\+$/ }
          specify { segments[1].embedded_pdf.should match /^DNSGa.+U9GCg==$/ }
        end
      end # End 'ZEF with embedded data'
    end # End 'through its ZEFs'

  end

end