# coding: utf-8
require 'openssl'
require 'base64'
require 'digest/sha1'
require 'json'
require 'logger'
require 'ostruct'
require 'httparty'

module Gpsoauth4r


  class Auth

    attr_reader :connection, :auth_token

    def initialize(logger, email, passwd)
      @logger = logger
      @email = email
      @passwd = passwd
      @auth_url = "https://android.clients.google.com/auth"
    end

    def auth_request(data)
      response = HTTParty.post(@auth_url, :body => data)
      raise 'http error' unless response.success?
      puts response
      return parse_properties(response.body)
    end

    def post(url, data)
      headers = data[:headers]
      headers['Authorization'] = @auth_token
      headers['Accept-Encoding'] = 'gzip, deflate'
      return HTTParty.post(url, data)
    end
    
    def login(service)
      read_from_file_or_request_master_token()
      @auth_token = "GoogleLogin auth=" + auth_request({
                                                         'EncryptedPasswd' => @master_token,
                                                         'Email' => @email,
                                                         'service' => service,
                                                         'accountType' => 'HOSTED_OR_GOOGLE',
                                                         'has_permission' => '1',
                                                         'app' => 'com.google.android.music',
                                                         'client_sig' => '38918a453d07199354f8b19af05ec6562ced5788'
                                                       })['Auth']
      @logger.info('got oauth token')
    end

    MASTER_TOKEN_FILENAME = '.master-token'
    def read_from_file_or_request_master_token()
      begin
        File.open(MASTER_TOKEN_FILENAME) do |io|
          @master_token = io.read
          @logger.info('got master token from .master-token')
        end
      rescue
        encrypted_password = signature(@email, @passwd)
        @master_token = auth_request({
                                       'EncryptedPasswd' => encrypted_password,
                                       'Email' => @email,
                                       'accountType' => 'HOSTED_OR_GOOGLE',
                                       'add_account' => '1',
                                       'has_permission' => '1',
                                       'service' => 'ac2dm'
                                     })['Token']
        File.write(MASTER_TOKEN_FILENAME, @master_token)
        @logger.info('got fresh master token')
      end
    end

    def parse_properties(s)
      return s.split("\n").inject({}) do |res, l|
        idx = l.index('=')
        key = l[0...idx]
        value = l[idx+1..-1]
        res[key] = value
        res
      end
    end
    
    def bin_to_hex(s)
      s.map { |b| sprintf("%02x", b) }.join(':')
    end
    
    def string_to_hex(s)
      bin_to_hex(s.bytes)
    end
    
    def divmod(bn, v)
      bn = bn.to_s.to_i if bn.is_a?(OpenSSL::BN)
      return bn.divmod(v)
    end

    def serialize_number(n, min_size=nil)
      res = []
      n, mod = divmod(n, 256)
      while mod > 0 || n > 0
        res << mod
        n, mod = divmod(n, 256)
      end
      res = res.reverse
      if min_size
        if res.size < min_size
          res = Array.new(min_size - res.size, 0) + res
        end
      end
      return res
    end

    def serialize_public_key(key)
      modulus = key.n
      exponent = key.e
      return serialize_number(modulus.num_bytes, 4) + serialize_number(modulus) + serialize_number(exponent.num_bytes, 4) + serialize_number(exponent)
    end

    def signature(email, passwd)
      b64Key7_3_29 = "AAAAgMom/1a/v0lblO2Ubrt60J2gcuXSljGFQXgcyZWveWLEwo6prwgi3" +
		                 "iJIZdodyhKZQrNWp5nKJ3srRXcUW+F1BD3baEVGcmEgqaLZUNBjm057pK" +
		                 "RI16kB0YppeGx5qIQ5QjKzsR8ETQbKLNWgRY0QRNVz34kMJR3P/LgHax/" +
		                 "6rmf5AAAAAwEAAQ=="
      binary_key = Base64.decode64(b64Key7_3_29)
      modulus, rest = get_data_and_rest(@binary_key)
      exponent, rest = get_data_and_rest(rest)
      raise "not all data was consumed  #{rest.size}" if rest.size > 0
      @key = OpenSSL::PKey::RSA.new
      @key.e = OpenSSL::BN.new(exponent)
      @key.n =  OpenSSL::BN.new(modulus)
      return Base64.urlsafe_encode64("\x00" +
                              digest_of_public_key(@key) +
                              encrypted_email_and_password(email, passwd, @key))
    end

    def encrypted_email_and_password(email, passwd, key)
      return key.public_encrypt(email + "\x00" + passwd, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
    end

    def digest_of_public_key(key)
      return Digest::SHA1.digest(serialize_public_key(key).pack('c*'))[0...4]
    end

    def take_and_drop(blob, n)
      first = blob[0...n]
      rest = blob[n..-1]
      return first, rest
    end

    def get_data_and_rest(blob)
      length, rest = take_and_drop(blob, 4)
      length = convert_to_number(length)
      number, rest = take_and_drop(rest, length)
      return convert_to_number(number), rest
    end

    def convert_to_number(blob)
      return blob.unpack("C*").inject(0) do |sum, byte|
        sum * 256 + byte
      end
    end
  end

end
