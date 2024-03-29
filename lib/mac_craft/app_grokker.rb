module MacCraft

  # This class bears a little explaining - it is central to this whole setup. We
  # want to create standalone applications that directly launches the Mincraft app
  # already configured with a player name and a UUID. In order to do this, we
  # have to start the real Minecraft app and then parse the command line options
  # used in that Java application.
  #
  # The `AppGrokker` understands how to parse those command line options and
  # extract all the information needed by our `files/minecraft-client.sh.erb`
  # template file.
  class AppGrokker
    MINECRAFT_APP = "/Applications/Minecraft.app".freeze
    JAVA_MAIN     = "net.minecraft.client.main.Main".freeze

    # the items of intereste we want to parse from the Minecraft
    # command line options
    attr_reader \
      :app_support,
      :java_home,
      :java_library_path,
      :java_opts,
      :jars,
      :version,
      :minecraft_opts

    # Standard initializer that expands out the full application support path
    # for the Minecraft application.
    def initialize(app_support: File.expand_path("~/Library/Application Support/minecraft"))
      @app_support = app_support.freeze
      @java_opts = []
      @minecraft_opts = []
    end

    # Do the actual command line retrieval and parsing. The end result is that
    # all the attributes of this class will be populated with values. If the
    # Minecraft app is not running, we make an attempt to start the app.
    def grok
      installed?

      cmd = get_command
      if cmd.nil? || cmd.empty?
        launch_minecraft!
        cmd = get_command
        abort "Sorry, Minecraft does not appear to be running :(" if cmd.nil? || cmd.empty?
      end

      parse(cmd: cmd)
      self
    end

    # Returns `true` if Minecraft is installed in the usual location. Otherwise
    # this method will abort the program with a nice message.
    def installed?
      return true if File.exists?(MINECRAFT_APP)
      abort "Sorry, Minecraft does not appear to be installed :("
    end

    # Fire up the Minecraft launcher and then ask the user to start the
    # Minecraft app itself. The user has to press the `Enter` key when the app
    # is up and running.
    def launch_minecraft!
      puts \
        "==========================================\n" +
        "We need to parse the command used to launch the Minecraft app.\n" +
        "The Minecraft app needs to be running in order to do this, but a game does\n" +
        "not need to be active.\n\n" +
        "Please press the \"Play\" button in the Minecraft launcher and then press\n" +
        "`Enter` in this window after Minecraft is up and running.\n" +
        "==========================================\n\n" +
        "Press `Enter` when ready to continue"

      %x(open #{MINECRAFT_APP})
      $stdin.gets  # wait for the user to press Enter
      self
    end

    # Get the command used to launch the Mincraft Java app. This will return an
    # empty string if Minecraft is not running.
    def get_command
      cmd = %x(ps -xo command | grep -i '#{JAVA_MAIN}' | grep -v grep)
      cmd.strip!
      cmd
    end

    # Parse the given `cmd` that was used to launch the Minecraft Java app. This
    # will extract the `JAVA_HOME` used to run Minecraft along with all the
    # flags and options passed to the JVM and the app itself.
    def parse(cmd: nil)
      # figuring which Java version is being used so we can use it too
      cmd.slice! %r/(^.*)\/bin\/java\s+/
      @java_home = $1.sub(MINECRAFT_APP, "$APP").
                      sub(Dir.home, "$HOME")

      # remvoe the main Java class from the command line so we can get at all the flags
      cmd   = cmd.sub(%r/\s+#{Regexp.escape(JAVA_MAIN)}\s+/, " ")
      flags = cmd.split(%r/\s+(?=-)/)

      # iterate over the flags and pull out data we need
      flags.each { |flag| parse_flag(flag: flag) }

      # replace the literal version number with a VERSION variable
      jars.each do |jar|
        next unless jar =~ %r/#{Regexp.escape(version)}\.jar$/
        jar.gsub!(version, "$VERSION")
      end
    end

    # Inspect a single `flag` and decicde what information (if any) to store for
    # later use.
    def parse_flag(flag:)
      case flag
      when %r/\A-Djava\.library\.path=(.*)/
        @java_library_path = $1

      when %r/\A-cp\s+(.*)/
        @jars = $1.split(":").map { |jar| jar.sub(app_support, "$APP_SUPPORT") }

      when %r/\A--version\s+(.*)/
        @version = $1

      # remove user-specific game settings
      when %r/\A--(?:username|uuid|accessToken)\s+/
        nil

      when %r/\A(--[[:alpha:]]+)\s+(.*)/
        option = $1
        value = $2.sub(app_support, "$APP_SUPPORT")
        @minecraft_opts << "#{option} \"#{value}\""

      when %r/\A(-[A-Za-z][^=\s]+)(?:=(.*))?/
        option = $1
        if $2
          value = $2 ? $2.sub(app_support, "$APP_SUPPORT") : nil
          option = "#{option}=\"#{value}\""
        end
        @java_opts << option
      end
    end
  end
end
