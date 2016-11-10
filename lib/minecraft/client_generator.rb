module Minecraft
  class ClientGenerator
    JAVA_MAIN = "net.minecraft.client.main.Main".freeze

    attr_reader \
      :username,
      :app_support,
      :app_icon,
      :java_home,
      :java_library_path,
      :jars,
      :version,
      :minor_version,
      :launcher_version

    def initialize(username:, filename: 'minecraft-client.sh')
      @username = username
      @app_support = File.expand_path("~/Library/Application Support/minecraft").freeze
    end

    def generate_script
      cmd = command
      abort "Minecraft does not appear to be running" if cmd.nil? || cmd.empty?

      parse(cmd: cmd)
      pin_native_libs!

      renderer = ERB.new(template, nil, "<>")
      renderer.result(binding)
    end

    def pin_native_libs!
      src  = java_library_path
      dest = java_library_path.sub(%r/#{Regexp.escape(version)}-natives-\d+$/, "#{version}-natives")

      FileUtils.rm_r(dest) if File.exists?(dest)
      FileUtils.cp_r(src, dest)
    end

    def command
      cmd = `ps -xo command | grep -i '#{JAVA_MAIN}' | grep -v grep`
      cmd.strip!
      cmd
    end

    def parse(cmd: nil)
      cmd.slice! %r/(^.*)\/bin\/java\s+/
      @java_home = $1.sub("/Applications/Minecraft.app", "$APP")

      cmd   = cmd.split(%r/(^.*)\s+#{Regexp.escape(JAVA_MAIN)}\s+(.*$)/).join(" ").strip
      flags = cmd.split(%r/\s+(?=-)/)

      flags.each { |flag| parse_flag(flag: flag) }

      jars.each do |jar|
        next unless jar =~ %r/#{Regexp.escape(version)}\.jar$/
        jar.gsub!(version, "$VERSION")
      end
    end

    def parse_flag(flag:)
      case flag
      when %r/^-Xdock:icon=(.*)/
        @app_icon = $1.sub(app_support, "$APP_SUPPORT")
      when %r/^-Djava\.library\.path=(.*)/
        @java_library_path = $1
      when %r/^-cp\s+(.*)/
        @jars = $1.split(":").map { |jar| jar.sub(app_support, "$APP_SUPPORT") }
      when %r/^--version\s+(.*)/
        @version = $1
      when %r/^--assetIndex\s+(.*)/
        @minor_version = $1
      when %r/^--nativeLauncherVersion\s+(.*)/
        @launcher_version = $1
      end
    end

    def template
      File.read("files/minecraft-client.sh.erb")
    end

  end
end

gen = Minecraft::ClientGenerator.new(username: "Papa")
puts gen.generate_script
