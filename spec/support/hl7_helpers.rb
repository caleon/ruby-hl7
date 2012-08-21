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

  def tmp_hl7_file(name)
    hl7_file(name, tmp_path)
  end

  def hl7_file(name, dir = nil)
    File.join(dir || root_path, "#{name}.hl7")
  end

  def write_hl7_composite_files!
    if example.metadata[:segment]
      segment_keys  << [example.metadata[:segment],
                        example.metadata[:variant]].compact.join.to_sym
    end

    File.exists?(test_hl7_file) or File.open(test_hl7_file,
      'w') { |f| f.puts ordered_keys.map { |p| IO.read hl7_file(names[p]) }.compact }
  end

  def my_parse_with(path = nil)
    path ||= test_hl7
    if true
      @raw_data = File.read(path).gsub("\n", "\r").gsub(/\r+/, "\r").sub(/[\s]+$/, '')
      @message = HL7::Message.parse(@raw_data)
    else
      @raw_data = open(path).readlines
      @message = HL7::Message.new(@raw_data)
    end
  end
end
