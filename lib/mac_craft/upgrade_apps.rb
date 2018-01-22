module MacCraft
  class UpgradeApps

    attr_reader :path

    def initialize(path: "pkg")
      @path = path
    end

    def upgrade
      each_app do |app|
        if server?(app)
          generator = ServerGenerator.new(version: version)
          generator.upgrade(app: app)
        elsif client?(app)
          m = %r/\/([^\/]+)?\s+Minecraft\.app\Z/.match app
          generator = ClientGenerator.new(username: m[1], app_grokker: app_grokker)
          generator.upgrade(app: app)
        else
          puts "Skipping #{app.inspect} - could not determine if client or server"
          next
        end
      end
    end

    def each_app
      if path =~ %r/\.app\Z/
        yield path
      elsif File.directory?(path)
        Dir.glob("#{path}/*.app").each { |app| yield app }
      else
        puts "Could not figure out what to do with #{path.inspect}  ¯\\_(ツ)_/¯"
      end
    end

    def app_grokker
      @app_grokker ||= AppGrokker.new.grok
    end

    def version
      app_grokker.version
    end

    def server?(app)
      resources = "#{app}/Contents/Resources"

      app =~ %r/\.app\Z/ &&
      File.directory?(app) &&
      File.directory?(resources) &&
      !Dir.glob("#{resources}/minecraft_server.*.jar").empty?
    end

    def client?(app)
      resources = "#{app}/Contents/Resources"

      app =~ %r/\.app\Z/ &&
      File.directory?(app) &&
      File.directory?(resources) &&
      File.directory?("#{resources}/natives") &&
      Dir.glob("#{resources}/minecraft_server.*.jar").empty?
    end
  end
end
