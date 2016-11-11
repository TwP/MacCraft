require 'json'

module Minecraft
  class Players
    include Enumerable
    PLAYERS_FILE = Minecraft.path("config/players.json")

    attr_reader :filename

    def initialize(filename: PLAYERS_FILE)
      @hash = {}
      @filename = filename
      load_players
    end

    def each
      if block_given?
        @hash.each { |player| yield player }
        self
      else
        @hash.each
      end
    end

    # Given a player `name` returns the Player instance. The same Player
    # instance will be returned each time the same name is used. The instance
    # will be created if it does not exist.
    #
    # Returns a Player instance
    def lookup(name)
      @hash[name] ||= Player.new(name: name)
    end
    alias [] lookup

    # Returns the number of players
    def length
      @hash.length
    end
    alias size length

    # Reads player information from the configured players `filename`. The JSON
    # data is converted into Player instances and stored in an internal Hash
    # variable.
    #
    # Returns this Players instance
    def load_players
      @hash.clear
      return self unless File.exists? filename

      ary = JSON.load(File.read(filename))
      ary.each do |hash|
        player = Player.new(symbolize_keys(hash))
        @hash[player.name] = player
      end

      self
    end

    # Writes player information to the configured players `filename`. The Player
    # instances are converted to JSON data and persisted to disk.
    #
    # Returns this Players instance
    def save_players
      ary = @hash.values.map { |player| player.to_hash }
      File.open(filename, "w") { |fd| fd.write(JSON.pretty_generate(ary)) }
      self
    end

    # Internal: Take the given `hash` and convert all String keys to Symbols.
    #
    # Returns a new Hash instance
    def symbolize_keys(hash)
      symbolized = {}
      hash.each {|k,v| symbolized[k.to_sym] = v}
      symbolized
    end
  end
end
