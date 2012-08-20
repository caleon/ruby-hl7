# encoding: UTF-8
$: << '../lib'
require 'ruby-hl7'

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.filter_run_excluding :broken => true

  require File.expand_path('../support/hl7_helpers', __FILE__)
  c.extend HL7Helpers

  c.before(:each, :embedded_tests) do
    if example.metadata[:segment]#, *example.metadata[:others]
      segment_keys  << [example.metadata[:segment],
                        example.metadata[:variant]].compact.join.to_sym
    end

    File.exists?(test_hl7) or File.open(test_hl7,
      'w') { |f| f.puts ordered_keys.map { |p| IO.read hl7(names[p]) }.compact }
    @raw_data = open(test_hl7).readlines
    @message = described_class.new(@raw_data)
  end
end

describe HL7::Message, 'containing PDF data', :embedded_tests, :configured, :message do
  let!(:names_array) { #{
    [[:MSH  , 'msh-common'],
     [:NTE3 , 'nte-thrice'],
     [:OBXa , 'obx-attaching'],
     [:OBXe , 'obx-embedding'],
     [:ZEF  , 'zef'],
     [:ZEF2 , 'zef-twice'],
     [:ZPS  , 'zps]']]
  }# }
  let!(:names) { Hash[names_array] }

  let(:segment_keys)  { [:MSH, *example.metadata[:others]] }
  let(:ordered_keys)  { segment_keys.compact.sort_by { |k| names_array.map(&:first).index(k) } }
  let(:output_name)   { ordered_keys.map { |k| names[k] } * '-' }
  let(:test_hl7)      { tmp_hl7(output_name) }

  # subject { @message }

  it_should_behave_like 'a properly parsed Message'

  context 'when the PDF is embedded' do

    context 'directly on an OBX', :segment => :OBX, :variant => :e do
      it_should_behave_like 'a Message containing Segment of type', :OBX

      # its(:children) { should be_empty }
      # message[:OBX].children.should be_empty
      # it 'should not have ZEF children with embedded data'
    end

    # context 'on nested ZEF Segments', :segment => :ZEF, :others => [:OBXa] do
    #   it_should_behave_like 'a Message containing Segment of type', :ZEF

    #   describe 'OBX wrapping the ZEF Segments' do
    #     # its(:children) { should_not be_nil }
    #     # its(:children) { should_not be_empty }
    #   end

    #   context 'across two items', :variant => '2' do
    #     it_should_behave_like 'a Message containing Segment of type', :ZEF

    #     describe 'OBX wrapping the ZEF Segments' do
    #       # its(:children) { should_not be_nil }
    #       # its(:children) { should_not be_empty }
    #     end
    #   end

    # end

  end

end