require 'forwardable'

module MacCraft
  class ClientGenerator
    extend Forwardable

    delegate %i[
      java_home
      java_library_path
      java_opts
      jars
      version
      minor_version
      minecraft_opts
    ] => :@app_grokker

    def initialize(username:, app_grokker: nil)
      @player = MacCraft.players[username]
      @app_grokker = app_grokker || AppGrokker.new
    end

    def username
      @player.name
    end

    def uuid
      @player.uuid
    end

    def upgrade(app:)
      resources = "#{app}/Contents/Resources"

      unless app =~ %r/\.app\Z/ && File.directory?(app) && File.directory?(resources) &&
             File.directory?("#{resources}/natives") && Dir.glob("#{resources}/minecraft_server.*.jar").empty?
        puts "Skipping #{app.inspect} - doest not appear to be a Minecraft client application"
        return
      end

      puts "Upgrading client #{app.inspect} to version #{version} [#{username}]"
      MacCraft.prepare!

      natives    = copy_native_libs
      scriptname = generate_script

      FileUtils.rm_r("#{resources}/natives") if File.exists?("#{resources}/natives")
      FileUtils.cp_r(natives, resources)
      FileUtils.cp(scriptname, "#{resources}/script")
      FileUtils.chmod(0755, "#{resources}/script")
    end

    def generate
      MacCraft.prepare!
      @app_grokker.grok

      natives    = copy_native_libs
      scriptname = generate_script

      package_app(scriptname: scriptname, natives: natives)
    end

    def package_app(scriptname:, natives:)
      pwd = Dir.pwd
      Dir.chdir(MacCraft.tmp)

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

      FileUtils.mv("#{username} Minecraft.app", MacCraft.path("pkg"))
      puts "\nYour client is ready: `pkg/#{username} Minecraft.app`"

    ensure
      Dir.chdir(pwd)
    end

    def generate_script
      scriptname = MacCraft.tmp("minecraft-client.sh")
      File.open(scriptname, "w") do |fd|
        renderer = ERB.new(template, nil, "<>")
        fd.write(renderer.result(binding))
      end
      scriptname
    end

    def copy_native_libs
      src  = java_library_path
      dest = MacCraft.tmp("natives")

      FileUtils.rm_r(dest) if File.exists?(dest)
      FileUtils.cp_r(src, dest)
      dest
    end

    def template
      File.read(MacCraft.path("files/minecraft-client.sh.erb"))
    end
  end
end
