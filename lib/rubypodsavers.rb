#####################################################
#
#  Saves feed releases in different ways.
#  Use: saver=RubyPodSaver.create 'mypodcastname'
#       saver.save(release)
#
class RubyPodSaver
  attr_reader :name, :release

  DEFAULT_BASE=File.expand_path('~/.rubypodder')

  def initialize(new_name, opts={})
    name=(new_name)
    @base_path=opts[:base_path] || DEFAULT_BASE
  end

  def self.create(type, new_name, opts={})
    PODSAVERS[type].new(new_name,opts) || raise("Bad Podsaver type: #{type}")
  end

  def name= name
    @name = name.gsub(/[\/\\\0 ]+/, '_')
  end

  def save(rel)
    @release=rel
    ensure_dir full_dirname
    File.open(full_filename, "w") { |file| file.write release.content }
    if release.has_shownotes?
      ensure_dir shownotes_dirname
      File.open(shownotes_filename, "w") { |file| file.write release.shownotes }
    end
  end

  def ensure_dir dir
    return true if File.directory? dir
    File.makedirs dir
  end
end

class RubyPodSaverByName <RubyPodSaver

  def release_name
    "#{@name}-#{release.date_string}-#{"%05d" % release.index}.#{release.format}"
  end

  def shownotes_name
    "#{@name}-#{release.date_string}-#{"%05d" % release.index}.html"
  end

  def full_dirname
    File.join @base_path, 'feeds', @name
  end
  
  def shownotes_dirname
    File.join @base_path, 'shownotes', @name
  end
  
  def full_filename
    File.join full_dirname, release_name
  end

  def shownotes_filename
    File.join shownotes_dirname, shownotes_name
  end
end

class RubyPodSaverByDate <RubyPodSaver

  def release_name
    "#{@name}-#{"%05d" % release.index}.#{release.format}"
  end

  def shownotes_name
    "#{@name}-#{"%05d" % release.index}.html"
  end

  def full_dirname
    File.join @base_path, 'feeds', release.date_string
  end
  
  def shownotes_dirname
    File.join @base_path, 'shownotes', release.date_string
  end
  
  def full_filename
    File.join full_dirname, release_name
  end

  def shownotes_filename
    File.join shownotes_dirname, shownotes_name
  end
end

class RubyPodSaverInHeap <RubyPodSaver

  def release_name
    "#{@name}-#{"%05d" % release.index}.#{release.format}"
  end

  def shownotes_name
    "#{@name}-#{"%05d" % release.index}.html"
  end

  def full_dirname
    File.join @base_path, 'feeds', 'all'
  end
  
  def shownotes_dirname
    File.join @base_path, 'shownotes', 'all'
  end
  
  def full_filename
    File.join full_dirname, release_name
  end

  def shownotes_filename
    File.join shownotes_dirname, shownotes_name
  end
end


class RubyPodSaver
    PODSAVERS=[
    :byname => RubyPodSaverByName,
    'byname'=> RubyPodSaverByName,
    :bydate => RubyPodSaverByDate,
    'bydate'=> RubyPodSaverByDate,
    :inheap => RubyPodSaverInHeap,
    'inheap'=> RubyPodSaverInHeap,
  ]
end