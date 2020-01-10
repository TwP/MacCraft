require 'nokogiri'
require 'net/http'

module MacCraft
  class MCVersions
    URL = "https://mcversions.net".freeze

    def self.lookup(version: "latest")
      self.new.lookup(version: version)
    end

    # Lookup the stable Minecraft server release identified by the given
    # `version` string. If a `version` is not provided, then the latest release
    # information will be returned.
    def lookup(version: "latest")
      if "latest" == version
        version = versions.first
      end

      stable_versions[version]
    end

    # Returns the list of available Minecraft server versions.
    def versions
      stable_versions.keys
    end

    # Returns a Hash of the stable Minecraft server releases.
    def stable_versions
      return @stable_versions if defined? @stable_versions
      @stable_versions = Hash.new

      stable.css("li.release").each do |node|
        version = node.attribute("id").value
        server = node.css("a.server")
        unless server.empty?
          url = server.attribute("href").value
          @stable_versions[version] = VersionInfo.new(version: version, url: url)
        end
      end

      @stable_versions
    end

    # Returns the `div` that contains the list of stable releases.
    def stable
      page.css("#content div.container div.row > div > ul.list-group")
    end

    # Returns a Nokogiri document containing the HTML of the `mcversions.net`
    # webpage.
    def page
      return @page if defined? @page
      content = Net::HTTP.get(URI(URL))
      @page = Nokogiri::HTML(content)
    end

    class VersionInfo
      attr_reader :version, :url, :jar

      def initialize(version:, url:)
        @version = version
        @url = url
        @jar = "minecraft_server.#{version}.jar"
      end
    end
  end
end
