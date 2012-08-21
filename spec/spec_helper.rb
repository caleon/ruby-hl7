# encoding: UTF-8
$: << '../lib'
require 'ruby-hl7'

RSpec.configure do |c|
  require 'support/hl7_helpers'
  c.extend HL7Helpers

  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.before(:all) do
    @temp_path = './spec/tmp'
    FileUtils.remove_dir @temp_path if File.exists?(@temp_path)
    FileUtils.mkdir_p    @temp_path

    [HL7::Message, HL7::Message::Segment].each { |k|
                                  k.send(:include, HL7Helpers::ShortInspector) }
  end

  c.before(:each, :message) do
    write_composite_hl7_files!
    @message = preferred_parse_with(@test_hl7_path)
  end
end
