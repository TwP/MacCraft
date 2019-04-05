require 'date'
require 'erb'
require 'fileutils'
require 'json'
require 'securerandom'

module MacCraft
  LIBPATH = File.expand_path('..', __FILE__)
  PATH    = File.expand_path('../..', __FILE__)

  # Returns the library path for the module. If any arguments are given, they
  # will be joined to the end of the library path using `File.join`.
  def self.libpath(*args, &block)
    rv = args.empty? ? LIBPATH : File.join(LIBPATH, args.flatten)
    if block
      begin
        $LOAD_PATH.unshift LIBPATH
        rv = block.call
      ensure
        $LOAD_PATH.shift
      end
    end
    return rv
  end

  # Returns the path for the module. If any arguments are given, they will be
  # joined to the end of the path using `File.join`.
  def self.path(*args, &block)
    rv = args.empty? ? PATH : File.join(PATH, args.flatten)
    if block
      begin
        $LOAD_PATH.unshift PATH
        rv = block.call
      ensure
        $LOAD_PATH.shift
      end
    end
    return rv
  end

  # Returns the path to the `tmp` folder. If any arguments are given, tehy will
  # be joined to the end of the `tmp` path using `File.join`.
  def self.tmp(*args)
    args.empty? ?
      File.join(PATH, "tmp") :
      File.join(PATH, "tmp", args.flatten)
  end

  # Returns the Players container that provides access to all the persistent
  # Player information.
  def self.players
    @players ||= Players.new
  end

  def self.cleanup!
    tmp = self.tmp
    if File.exists?(tmp)
      puts "Deleting the 'tmp' directory and all its contents"
      FileUtils.rm_r(tmp)
    end

    pkg = self.path("pkg")
    if File.exists?(pkg)
      puts "Deleting the 'pkg' directory and all its contents"
      FileUtils.rm_r(pkg)
    end

    nil
  end

  def self.prepare!
    tmp = self.tmp
    FileUtils.mkdir(tmp) unless File.exists?(tmp)

    pkg = self.path("pkg")
    FileUtils.mkdir(pkg) unless File.exists?(pkg)
  end
end

require_relative 'mac_craft/version'
require_relative 'mac_craft/mc_versions'
require_relative 'mac_craft/player'
require_relative 'mac_craft/players'
require_relative 'mac_craft/app_grokker'
require_relative 'mac_craft/client_generator'
require_relative 'mac_craft/server_generator'
require_relative 'mac_craft/upgrade_apps'
