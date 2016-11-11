require 'date'
require 'securerandom'

module Minecraft
  class Player

    attr_reader :name, :operator

    def initialize(name:, uuid: nil, operator: nil)
      @name     = name
      @uuid     = uuid
      @operator = operator
    end

    def uuid
      @uuid ||= [4, 2, 2, 2, 6].map { |bytes| SecureRandom.hex(bytes) }.join("-")
    end

    def compact_uuid
      uuid.tr("-","")
    end

    def operator?
      !@operator.nil? &&
      @operator >= 1  &&
      @operator <= 4
    end

    def to_hash
      {
        name: name,
        uuid: uuid,
        operator: operator
      }
    end

    def to_operator
      return unless operator?
      to_hash.merge(bypassesPlayerLimit: false)
    end

    def to_usercache
      {
        name: name,
        uuid: uuid,
        expiresOn: (DateTime.now + 60).strftime("%Y-%m-%d %H:%M:%S %z")  # in 60 days
      }
    end
  end
end
