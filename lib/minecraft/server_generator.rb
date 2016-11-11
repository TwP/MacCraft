module Minecraft
  class ServerGenerator

    attr_reader :version

    def initialize(version:)
      @version = version
    end

    def generate
      prepare!

      server_jar = download_server_jar
      package_app(server_jar: server_jar)
    end

    def package_app(server_jar:)
      pwd = Dir.pwd
      Dir.chdir(Minecraft.tmp)

      scriptname = render_erb(filename: "minecraft-server.sh")
      properties = render_erb(filename: "server.properties")
      eula       = render_erb(filename: "eula.txt")
      ops        = generate_ops
      usercache  = generate_usercache

      args = %W[
        /usr/local/bin/platypus -R
        -a 'Minecraft Server'
        -o 'None'
        -i '#{Minecraft.path("icons/minecraft-server.icns")}'
        -V '#{version}'
        -u 'Tim Pease'
        -I 'com.pea53.Minecraft.server'
        #{scriptname}
      ]

      system args.join(" ")  # we want to see platypus output

      # a bug in Platypus 5.1 prevents the -f / --bundled-file option from working
      # see https://github.com/sveinbjornt/Platypus/issues/78
      # this is our workaround for the time being
      dest = "Minecraft Server.app/Contents/Resources/"
      FileUtils.cp(server_jar, dest)

      Dir.glob(Minecraft.path("files/*.json")).each { |fn| FileUtils.cp(fn, dest) }

      FileUtils.cp(properties, dest)
      FileUtils.cp(eula, dest)
      FileUtils.cp(ops, dest)
      FileUtils.cp(usercache, dest)

    ensure
      Dir.chdir(pwd)
    end

    def generate_ops
      filename = Minecraft.tmp("ops.json")
      File.open(filename, "w") do |fd|
        fd.write(JSON.pretty_generate(Minecraft.players.operators))
      end
      filename
    end

    def generate_usercache
      filename = Minecraft.tmp("usercache.json")
      File.open(filename, "w") do |fd|
        fd.write(JSON.generate(Minecraft.players.usercache))
      end
      filename
    end

    def render_erb(filename:)
      template = Minecraft.path("files", "#{filename}.erb")
      dest = Minecraft.tmp(filename)

      File.open(dest, "w") do |fd|
        renderer = ERB.new(File.read(template), nil, "<>")
        fd.write(renderer.result(binding))
      end

      dest
    end

    def download_server_jar
      jar  = "minecraft_server.#{version}.jar"
      url  = "https://s3.amazonaws.com/Minecraft.Download/versions/#{version}/#{jar}"
      dest = Minecraft.tmp(jar)

      puts "Downloading jar #{url.inspect}"
      system "/usr/bin/curl -XGET '#{url}' > '#{dest}'"  # we want to see curl output

      dest
    end

    def datestamp
      Time.now.strftime("%a %b %d %H:%M:%S %Z %Y")  # Wed Nov 09 19:49:30 MST 2016
    end

    def prepare!
      tmp = Minecraft.tmp
      FileUtils.rm_r(tmp) if File.exists?(tmp)
      FileUtils.mkdir(tmp)
    end
  end
end
