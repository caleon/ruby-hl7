# encoding: UTF-8
require 'ruby-hl7'
# External EDI Specs Ver 10.2.pdf p.70
class HL7::Message::Segment::ZEF < HL7::Message::Segment
  weight 8
  add_field :set_id,        :idx => 1 # ZEF-1 "Sequence Number", 1~9999
  add_field :embedded_pdf,  :idx => 2 # ZEF-2
end
