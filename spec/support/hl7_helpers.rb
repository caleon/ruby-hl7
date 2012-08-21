# encoding: UTF-8
module HL7Helpers
  def self.extended(klass)
    klass.send(:include, self)
  end

  NAMES_ARRAY = [
      [:MSH  , 'msh-common'],
      [:NTE3 , 'nte-thrice'],
      [:OBX  , 'obx'],
      [:OBXa , 'obx-attaching'],
      [:OBXe , 'obx-embedding'],
      [:ZEF  , 'zef'],
      [:ZEF2 , 'zef-twice'],
      [:ZPS  , 'zps]']]

  NAMES_HASH = Hash[NAMES_ARRAY]

  def root_path
    File.expand_path('./test_data/pdfs')
  end

  def tmp_path
    File.expand_path(@temp_path)
  end

  def tmp_hl7_path(name)
    hl7_path(name, tmp_path)
  end

  def hl7_path(name, dir = nil)
    File.join(dir || root_path, "#{name}.hl7")
  end

  def hl7_keys
    return @hl7_keys if @hl7_keys
    key = example.metadata.values_at(:type, :variant).join.to_sym rescue nil
    @hl7_keys = [:MSH, key, *example.metadata[:others]].compact.
                               sort_by { |k| NAMES_ARRAY.map(&:first).index(k) }
  end

  def write_composite_hl7_files!
    names = hl7_keys.map { |k| NAMES_HASH[k] }
    @test_hl7_path = path = tmp_hl7_path(names.join('-'))
    return if File.exists?(path)
    File.open(path, 'w') { |f| f.puts names.map { |n| IO.read(hl7_path(n)) } }
  end

  def preferred_parse_with(path)
    @raw_data = File.read(path).gsub("\n", "\r").gsub(/\r+/, "\r").sub(/[\s]+$/, '')
    @message = HL7::Message.parse(@raw_data)
  end

  module ShortInspector
    def inspect
      vars = '...'#self.instance_variables.map{|v| "#{v}=.."}.join(", ")
      "<#{self.class}: #{vars}>"
    end
  end

end
