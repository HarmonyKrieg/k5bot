# encoding: utf-8
# This file is part of the K5 bot project.
# See files README.md and COPYING for copyright and licensing information.

# IRCPluginManager manages all plugins

class IRCPluginManager < IRCListener
  attr_reader :plugins, :commands, :config

  def initialize(router, config)
    @plugins = {}
    @commands = {}
    @router = router
    @config = config

  end

  def load_all_plugins()
    do_load_plugins(@config)
  end

  def load_plugin(name)
    config_entry = find_config_entry(name)

    do_load_plugins([config_entry])
  end

  def unload_plugin(name)
    begin
      p = @plugins[name.to_sym]
      return false unless p

      dependants = []
      @plugins.keys.each do |suspectName|
        pluginClass = Kernel.const_get(suspectName.to_sym)
        dependants << suspectName if pluginClass::Dependencies and pluginClass::Dependencies.include? name.to_sym
      end

      unless dependants.empty?
        puts "Cannot unload plugin '#{name}', the following plugins depend on it: #{dependants.join(', ')}"
        return false
      end

      error = p.beforeUnload
      if error
        puts "'#{name}' refuses to unload: #{error}"
        return false
      end

      p.commands.keys.each{|c| @commands.delete c} if p.commands
      @plugins.delete name.to_sym
      @router.unregister p
      Object.send :remove_const, name.to_sym
    rescue => e
      puts "Cannot unload plugin '#{name}': #{e}\n\t#{e.backtrace.join("\n\t")}"
      return false
    end
    true
  end

  private

  def find_config_entry(name)
    name = name.to_sym

    config_entry = @config.find do |p|
      n, _ = parse_config_entry(p)
      n == name
    end
    config_entry || name
  end

  def parse_config_entry(p)
    if p.is_a?(Hash)
      name = p.keys.first
      config = p[name]
    else
      name = p
      config = nil
    end
    return name.to_sym, config
  end

  def do_load_plugins(to_load)
    return false unless to_load

    loading = []
    to_load.each do |p|
      name, config = parse_config_entry(p)
      unless plugins[name] # filter out already loaded plugins
        loading << [name, config]
      end
    end

    overall = nil
    loading.each do |name, config|
      overall = false if !do_load_plugin(name, config, loading)
    end

    loading.each do |name, _|
      if (plugin = @plugins[name])
        begin
          print "Initializing plugin #{name}..."
          plugin.afterLoad
          @router.register plugin
          puts "done."
        rescue ScriptError, StandardError => e
          puts "Cannot initialize plugin '#{name}': #{e}"
          overall = false
        end
      end
    end

    overall = true if overall == nil
    overall
  end

  def do_load_plugin(name, config, loading)
    return true if plugins[name.to_sym] # success, if already loaded
    return false if name !~ /\A[a-zA-Z0-9]+\Z/m
    begin
      requested = "IRC/plugins/#{name.to_s}/#{name.to_s}.rb"
      filename = Dir.glob(requested, File::FNM_CASEFOLD).first
      unless requested.eql? filename
        puts "Cannot find plugin '#{name.to_s}'."
        return false
      end

      load filename
      pluginClass = Kernel.const_get(name.to_sym)
      if pluginClass::Dependencies
        lacking = []
        pluginClass::Dependencies.each do |d|
          lacking << d unless (@plugins[d]) || (loading && loading.include?(d))
        end
        unless lacking.empty?
          Object.send(:remove_const, name.to_sym)
          return false
        end
      end

      print "Loading #{name}..."
      p = @plugins[name.to_sym] = pluginClass.new(self)
      p.config = (config || {}).freeze
      p.commands.keys.each{|c| @commands[c] = p} if p.commands
      puts "done."
    rescue ScriptError, StandardError => e
      puts "Cannot load plugin '#{name}': #{e}"
      return false
    end
    true
  end
end
