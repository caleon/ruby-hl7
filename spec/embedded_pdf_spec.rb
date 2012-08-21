# encoding: UTF-8
require 'spec_helper'
require 'support/hl7_shared_examples'

describe HL7::Message, 'containing PDF data', :message do

  describe '[Setup]' do
    it 'dynamically wrote a composite HL7 file' do
      @test_hl7_path.should match /[-a-z0-9]{3,}\.hl7$/
      File.should exist @test_hl7_path
    end

    it 'wrote a file containing validly parse-able blob' do
      @raw_data.should_not be_nil
      @raw_data.should be_a_kind_of Enumerable
    end
  end

  it_behaves_like 'a properly parsed Message'

  context 'when the PDF is embedded', 'on an OBX', :type => :OBX do

    context 'directly', :variant => :e do
      it_behaves_like 'a properly parsed Message'
      it_behaves_like 'a Message containing Segment of type', :OBX

      describe 'OBX', :segment do
        it_behaves_like 'OBX Segments within a proper Message'

        context 'w/ the embedded data' do
          its(:children) { should be_empty }
          its(:children) { should_not satisfy { |ary| ary.detect { |s|
            s.e0 == 'ZEF' && s.embedded_pdf
          }}}
        end
      end
    end

    context 'through its ZEFs', :variant => :a, :others => [:ZEF] do
      it_behaves_like 'a properly parsed Message'
      it_behaves_like 'a Message containing Segment of type', :ZEF

      describe 'OBX', :segment do
        it_behaves_like 'OBX Segments within a proper Message'

        context 'wrapping the embedding ZEFs' do
          its(:children) { should_not be_empty }
          its(:children) { should satisfy { |ary| ary.detect { |s|
            s.e0 == 'ZEF' && s.embedded_pdf && s.embedded_pdf.length > 0
          } } }
        end
      end

      describe 'ZEF', :segment, :type => :ZEF, :variant => nil, :others => [:OBXa] do
        it_behaves_like 'ZEF Segments within a proper Message'

        context 'with the embedded data' do
          context 'on one Segment', :variant => nil do
            specify { segments.should have(1).zef_segment }

            it_behaves_like 'ZEF Segments w/ embedded data' do
              let(:expected_parent) { message[:OBX] }
              let(:expected_set_id) { '1' }
              its(:embedded_pdf) { should match /^JVBER.+U9GCg==$/ }
            end
          end

          context 'on two contiguous Segments', :variant => '2' do
            specify { segments.should have(2).zef_segments }
            before(:each) { @zef1, @zef2 = segments }

            describe 'ZEF 1' do
              subject { @zef1 }
              it_behaves_like 'ZEF Segments w/ embedded data' do
                let(:expected_parent) { message[:OBX] }
                let(:expected_set_id) { '1' }
                its(:embedded_pdf) { should match /^JVBER.+GwjBg\+$/ }
              end
            end

            describe 'ZEF 2' do
              subject { @zef2 }
              it_behaves_like 'ZEF Segments w/ embedded data' do
                let(:expected_parent) { message[:OBX] }
                let(:expected_set_id) { '2' }
                its(:embedded_pdf) { should match /^DNSGa.+U9GCg==$/ }
              end
            end

          end

        end # End 'ZEF with embedded data'
      end

    end # End 'through its ZEFs'

  end

end