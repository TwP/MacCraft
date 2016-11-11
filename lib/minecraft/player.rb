module Minecraft
  class Player

    attr_reader :name, :operator

    def initialize(name:, uuid: nil, operator: nil)
      @name     = name
      @uuid     = uuid
      @operator = operator
    end

    # Returns this Player's UUID in a dashed hex-string format.
    def uuid
      @uuid ||= [4, 2, 2, 2, 6].map { |bytes| SecureRandom.hex(bytes) }.join("-")
    end

    # Returns `true` if this Player has operator privileges.
    def operator?
      !@operator.nil? &&
      @operator >= 1  &&
      @operator <= 4
    end

    # Returns a Hash representation used to persist this Player to disk in our
    # `players.json` file. This is an internal format that is not used by
    # Minecraft.
    def to_hash
      {
        name: name,
        uuid: uuid,
        operator: operator
      }
    end

    # Returns a Hash representation suitable for use in the `ops.json` server
    # file.
    def to_operator
      return unless operator?
      to_hash.merge(bypassesPlayerLimit: false)
    end

    # Returns a Hash representation suitable for use in the `usercache.json`
    # server file.
    def to_usercache
      {
        name: name,
        uuid: uuid,
        expiresOn: (DateTime.now + 60).strftime("%Y-%m-%d %H:%M:%S %z")  # in 60 days
      }
    end
  end
end
