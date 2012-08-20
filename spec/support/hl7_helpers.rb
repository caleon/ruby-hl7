module HL7Helpers
  def self.extended(klass)
    klass.before(:all) { FileUtils.mkdir_p tmp_path }
     # klass.after(:all) { FileUtils.remove_dir tmp_path }
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
    include_examples 'a Message containing Segment of type', type

    # describe "The #{type} Segment", :segment => type do

    # end
  end
end

shared_examples_for 'a Message containing Segment of type' do |type|
  # include_context
  # before(:each) do
  #   example.metadata[:segment] ||= type
  #   if type == :OBX
  #     md = example.metadata.dup
  #     md.delete(:example_group)
  #     md.delete(:example_group_block)
  #     md.delete(:caller)
  #     puts "Example's metadatas is: #{md.inspect}"
  #   end

  # end

  let(:segments_by_name) { message.instance_variable_get(:@segments_by_name) }

  it "includes an entry in its segments_by_name cache for #{type} Segments" do
    segments_by_name.should_not be_nil
    # segments_by_name.should_not be_empty
    # segments_by_name[type].should_not be_nil
    # segments_by_name[type].should_not be_empty
  end
end

shared_context 'Segment object', :segment do
  let(:type) { example.metadata[:segment] }
  let(:segment) { message[]}
  # subject { segment }
  # its([type]) { should be_a described_class::Segment.const_get(type) }
end

shared_examples_for 'a proper Segment' do
  # it { should_not be_nil }

end