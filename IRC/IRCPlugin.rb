# encoding: utf-8
# This file is part of the K5 bot project.
# See files README.md and COPYING for copyright and licensing information.

# IRCPlugin is the superclass of all plugins

require 'IRC/Listener'

module IRCPlugin
  include BotCore::Listener

  # Configuration options set for this plugin
  # This variable will always be a hash and never nil
  attr_reader :config

  # The plugin manager, that manages this plugin
  attr_reader :plugin_manager

  # A short description of this plugin
  DESCRIPTION = nil

  # A hash with available commands and their descriptions
  COMMANDS = nil

  # A list containing the names of the plugins this plugin depends on
  DEPENDENCIES = nil

  def initialize(manager, config)
    @plugin_manager = manager
    @config = config
  end

  # Called by the plugin manager after all plugins have been loaded.
  # Use this method to initialize anything dependent on other plugins.
  # Convenient also to use it as a replacement for initialize, since
  # there is no need to keep track of arguments call super.
  def afterLoad; end

  # Called by the plugin manager before the plugin is unloaded.
  # If this method returns anything other than nil or false, the plugin
  # will not be unloaded and its return value will be displayed in the log.
  def beforeUnload; end

  # Returns the name of this plugin
  def name; self.class.name; end

  # Returns the root dir of this plugin
  def plugin_root; "#{File.dirname(__FILE__)}/plugins/#{name}"; end

  def description
    if self.class::DESCRIPTION
       self.class::DESCRIPTION
    elsif self.class.const_defined?('Description')
      "Error in plugin #{name}: Mixed case Description constant in plugins is deprecated. Change it to DESCRIPTION"
    end
  end

  def commands
    if self.class::COMMANDS
      self.class::COMMANDS
    elsif self.class.const_defined?('Commands')
      {("error_#{name.downcase}").to_sym => "Error in plugin #{name}: Mixed case Commands constant in plugins is deprecated. Change it to COMMANDS"}
    end
  end

  def dependencies
    if self.class::DEPENDENCIES
      self.class::DEPENDENCIES
    elsif self.class.const_defined?('Dependencies')
      raise "Error in plugin #{name}: Mixed case Dependencies constant in plugins is deprecated. Change it to DEPENDENCIES"
    end
  end

  def load_helper_class(class_name)
    class_name = class_name.to_sym

    unload_helper_class(class_name, true)
    begin
      load "#{plugin_root}/#{class_name}.rb"
    rescue ScriptError, StandardError => e
      puts "Cannot load #{class_name}: #{e}"
    end
  end

  def unload_helper_class(class_name, fail_silently = false)
    class_name = class_name.to_sym
    begin
      Object.send :remove_const, class_name
    rescue ScriptError, StandardError => e
      puts "Cannot unload #{class_name}: #{e}" unless fail_silently
    end
  end

  def dispatch_message_by_command(msg, allowed_commands = nil)
    bot_command = msg.bot_command
    return unless (!allowed_commands || allowed_commands.include?(bot_command))
    meth = "cmd_#{bot_command}"
    if self.respond_to?(meth) && (!block_given? || yield(msg))
      self.__send__(meth, msg)
    end
    true
  end

  def self.remove_required(lib)
    $LOADED_FEATURES.delete_if do |path|
      File.dirname(path).end_with?(lib.chomp(File::SEPARATOR))
    end
  end
end
