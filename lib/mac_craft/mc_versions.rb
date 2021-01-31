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

      stable.each do |node|
        version = node.xpath("div[1]/p/text()").text
        next unless version =~ %r/\d+\.\d+(\.\d+)?/

        details = node.xpath("div[2]/a/@href").first.value
        details = URL + details
        @stable_versions[version] = VersionInfo.new(version: version, details: details)
      end

      @stable_versions
    end

    # Returns the list of `div` for the stable releases.
    def stable
      page.xpath("/html/body/main/div/div[2]/div[1]/div/div")
    end

    # Returns a Nokogiri document containing the HTML of the `mcversions.net`
    # webpage.
    def page
      return @page if defined? @page
      content = Net::HTTP.get(URI(URL))
      @page = Nokogiri::HTML(content)
    end

    class VersionInfo
      attr_reader :version, :details, :jar

      def initialize(version:, details:)
        @version = version
        @details = details
        @jar = "minecraft_server.#{version}.jar"
        @url = nil
      end

      def url
        return @url unless @url.nil?

        content = Net::HTTP.get(URI(details))
        page = Nokogiri::HTML(content)
        @url = page.xpath("//a[@download=\"minecraft_server-#{version}.jar\"]/@href").first&.value
      end
    end
  end
end
