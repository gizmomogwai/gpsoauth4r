require 'spec_helper'
require 'gpsoauth4r'
include Gpsoauth4r
describe Auth do
  it 'should parse a properties file' do
    expect(Auth.new(nil, '', '').parse_properties("abc=123\ndef=456")).to eql({'abc' => '123', 'def' => '456'})
  end
end
