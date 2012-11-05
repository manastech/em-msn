class Msn::Challenge
  ProductKey = "RG@XY*28Q5QHS%Q5"
  ProductId = "PROD0113H11T8$X_"
  F = "0x7FFFFFFF".to_i(16)
  E = "0x0E79A9C1".to_i(16)

  class << self
    def challenge(challenge, product_key = ProductKey, product_id = ProductId)
      md5hash = Digest::MD5.hexdigest "#{challenge}#{product_key}"
      md5array = md5hash.scan(/.{8}/)
      new_hash_parts = md5array.map! { |s| s.scan(/.{2}/).reverse.join.to_i(16) }
      md5array = new_hash_parts.map { |n| n & F }

      chlstring = "#{challenge}#{product_id}"
      chlstring = "#{chlstring}#{'0' * (chlstring.length % 8)}"

      chlstring_array = chlstring.scan(/.{4}/)
      chlstring_array.map! { |str| str.bytes.map { |b| b.to_s(16) }.reverse.join.to_i(16) }

      low = high = 0

      i = 0
      while i < chlstring_array.length
        temp = (md5array[0] * (((E * chlstring_array[i]) % F) + high) + md5array[1]) % F
        high = (md5array[2] * ((chlstring_array[i + 1] + temp) % F) + md5array[3]) % F
        low = low + high + temp;

        i += 2
      end

      high = (high + md5array[1]) % F
      low = (low + md5array[3]) % F
      key = (high << 32) + low

      new_hash_parts[0] ^= high;
      new_hash_parts[1] ^= low;
      new_hash_parts[2] ^= high;
      new_hash_parts[3] ^= low;

      new_hash_parts.map { |x| x.to_s(16).scan(/.{2}/).reverse.join }.join
    end

    def split_in_chunks(string, length)
      array = []
      i = 0
      while i < string.length
        array.push string[i ... i + length]
        i += length
      end
      array
    end
  end
end