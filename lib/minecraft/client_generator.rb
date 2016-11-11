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

    def initialize(username:)
      @username = username
      @app_support = File.expand_path("~/Library/Application Support/minecraft").freeze
    end

    def generate
      cmd = command
      abort "Minecraft does not appear to be running" if cmd.nil? || cmd.empty?

      prepare!
      parse(cmd: cmd)

      natives    = copy_native_libs
      scriptname = generate_script

      package_app(scriptname: scriptname, natives: natives)
    end

    def package_app(scriptname:, natives:)
      pwd = Dir.pwd
      Dir.chdir(Minecraft.tmp)

      args = %W[
        /usr/local/bin/platypus -R
        -a '#{username} Minecraft'
        -o 'None'
        -i '/Applications/Minecraft.app/Contents/Resources/favicon.icns'
        -V '#{version}'
        -u 'Tim Pease'
        -I 'com.pea53.Minecraft.client'
        #{scriptname}
      ]

      system args.join(" ")  # we want to see platypus output

      # a bug in Platypus 5.1 prevents the -f / --bundled-file option from working
      # see https://github.com/sveinbjornt/Platypus/issues/78
      # this is our workaround for the time being
      FileUtils.cp_r(natives, "#{username} Minecraft.app/Contents/Resources/")
    ensure
      Dir.chdir(pwd)
    end

    def generate_script
      scriptname = Minecraft.tmp("minecraft-client.sh")
      File.open(scriptname, "w") do |fd|
        renderer = ERB.new(template, nil, "<>")
        fd.write(renderer.result(binding))
      end
      scriptname
    end

    def copy_native_libs
      src  = java_library_path
      dest = Minecraft.tmp("natives")

      FileUtils.rm_r(dest) if File.exists?(dest)
      FileUtils.cp_r(src, dest)
      dest
    end

    def command
      cmd = %x(ps -xo command | grep -i '#{JAVA_MAIN}' | grep -v grep)
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
      File.read(Minecraft.path("files/minecraft-client.sh.erb"))
    end

    def prepare!
      tmp = Minecraft.tmp
      FileUtils.rm_r(tmp) if File.exists?(tmp)
      FileUtils.mkdir(tmp)
    end
  end
end
