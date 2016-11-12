require 'forwardable'

module Minecraft
  class ClientGenerator
    extend Forwardable

    delegate %i[
      app_support
      app_icon
      java_home
      java_library_path
      jars
      version
      minor_version
      launcher_version
    ] => :@app_grokker

    def initialize(username:, app_grokker: nil)
      @player = Minecraft.players[username]
      @app_grokker = app_grokker || AppGrokker.new
    end

    def username
      @player.name
    end

    def uuid
      @player.uuid
    end

    def generate
      Minecraft.prepare!
      @app_grokker.grok

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

      FileUtils.mv("#{username} Minecraft.app", Minecraft.path("pkg"))
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

    def template
      File.read(Minecraft.path("files/minecraft-client.sh.erb"))
    end
  end
end
