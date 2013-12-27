# encoding: utf-8

require_relative '../../IRCPlugin'

require 'fileutils'

class Kanastats < IRCPlugin
  Description = "Counts all chars used in channels the bot is connected to as well as private messages."

  Dependencies = [ :StorageYAML ]

  Commands = {
    :hirastats => "Returns hiragana usage statistics.",
    :katastats => "Returns katakana usage statistics.",
    :charstats => "How often the specified char was publicly used.",
    :wordstats => "How often the specified word was publicly used."
  }

  def afterLoad
    @storage = @plugin_manager.plugins[:StorageYAML]
    @stats = @storage.read('kanastats') || {}
    dir = @config[:data_directory]
    dir = dir || '~/.ircbot'
    @data_directory = File.expand_path(dir).chomp('/')
  end

  def beforeUnload
    @storage = nil
    @stats = nil
    @data_directory = nil
  end

  def store
    @storage.write('kanastats', @stats)
  end

  def on_privmsg(msg)
    case msg.botcommand
      when :hirastats
        output_hira(msg)
      when :katastats
        output_kata(msg)
      when :charstats
        charstat(msg)
      when :wordstats
        wordstats(msg)
      else if !msg.private?
        statify(msg.message)
        log(msg.message)
        store
      end
    end
  end

  def statify(text)
    text.split("").each do |c|
      if !@stats[c]
        @stats[c] = 0
      end
      @stats[c] += 1
    end
  end

  def output_hira(msg)
    output_array = Array.new
    "あいうえおかきくけこさしすせそたちつてとなにぬねのまみむめもはひふへほやゆよらりるれろわゐゑをんばびぶべぼぱぴぷぺぽがぎぐげござじずぜぞだぢづでどゃゅょぁぃぅぇぉ".split("").each do |c|
      if !@stats[c]
        @stats[c] = 0
      end
      output_array << "#{c} #{@stats[c].to_s()}"
    end
    until output_array.empty?
      chunk_size = output_array.size
      begin
        output_string = "Hiragana stats: #{output_array[0..chunk_size-1].join(' ')}"
        msg.reply( output_string, :dont_truncate => ( chunk_size > 1 ) )
      rescue
        chunk_size -= 1
        retry if chunk_size > 0
      end
      output_array.slice!( 0, chunk_size )
    end
  end

  def output_kata(msg)
    output_array = Array.new
    "アイウエオカキクケコサシスセソタチツテトナニヌネノマミムメモハヒフヘホヤユヨラリルレロワヰヱヲンバビブベボパピプペポガギグゲゴザジズゼゾダヂヅデドャュョァィゥェォ".split("").each do |c|
      if !@stats[c]
        @stats[c] = 0
      end
      output_array << "#{c} #{@stats[c].to_s()}"
    end
    until output_array.empty?
      chunk_size = output_array.size
      begin
        output_string = "Katakana stats: #{output_array[0..chunk_size-1].join(' ')}"
        msg.reply( output_string, :dont_truncate => ( chunk_size > 1 ) )
      rescue
        chunk_size -= 1
        retry if chunk_size > 0
      end
      output_array.slice!( 0, chunk_size )
    end
  end

  def charstat(msg)
    output_string = "The char '"
    c = msg.tail[0]
    if !@stats[c]
      @stats[c] = 0
    end
    output_string << c
    if @stats[c] == 0
      output_string << "' wasn't used so far."
    elsif @stats[c] == 1
      output_string << "' was used once."
    else
      output_string << "' was used " << @stats[c].to_s() << " times."
    end
    msg.reply output_string
  end

  def log(line)
    return unless line
    line << "\n"
    file = "#{@data_directory}/public_logfile"
    File.open(file, 'a') { |f| f.write(line) }
  end

  def wordstats(msg)
    word = msg.tail
    file = "#{@data_directory}/public_logfile"
    count = File.open(file) {|f| f.each_line.map {|l| l.scan(word).size}.inject(0, :+)}
    output_string = "The word '#{word}' "
    if count == 0
      output_string << "wasn't used so far."
    elsif count == 1
      output_string << "was used once."
    else
      output_string << "was used #{count} times."
    end
    msg.reply output_string
  end
end
