#!/usr/bin/env ruby

require "openssl"
require 'base64'
 
# We use the AES 256 bit cipher-block chaining symetric encryption
alg = "AES-256-CBC"

key = OpenSSL::Cipher::Cipher.new(alg).random_key

key64 = [key].pack('m')

File.open(ARGV[0], 'w') do |f|
  f << key64
end

