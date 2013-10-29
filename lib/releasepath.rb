#####################################################
#
#  Saves feed releases in different ways.
#  Use: saver=RubyPodSaver.create 'mypodcastname'
#       saver.save(release)
#

#####################################################
#
#  Generates path to store release, releasenotes, images, etc...
#

class ReleasePath
  attr_reader :release, :name, :serie, :base_path

  DEFAULT_BASE=File.expand_path('~/.rubypodder')

  def initialize(release, opts={})
    @release=release
    @serie = fix_name(@release.serie) || 'unsorted'
    @name  = fix_name(@release.name) || 'unnamed'
    @base_path = opts[:base_path] || DEFAULT_BASE
  end

  def self.create(type, release, opts={})
    PATH_TYPES[type].new(release,opts) || raise("Bad path type type: #{type}")
  end

  def name= str
    @name=fix_name(str)
  end

  def serie= str
    @serie=fix_name(str)
  end

  def fix_name name
    return nil if name.to_s == ''
    name.to_s.gsub(/[\/\\\0 ]+/, '_')
  end

  def release_file(mode='r', &block)
    ensure_dir full_dirname
    File.open(full_filename, mode) { |f|
      yield f
    }
  end

  def release_notes_file(mode='r', &block)
    ensure_dir shownotes_dirname
    File.open(shownotes_filename, mode) { |f|
      yield f
    }
  end

  def release_file?
    File.file? full_filename
  end

  def release_notes_file?
    File.file? release_file
  end

private

  def ensure_dir dir
    return true if File.directory? dir
    FileUtils.mkdir_p dir
  end
end

class ReleasePathByName <ReleasePath

  def release_name
    "#{@name}-#{release.date_string}-#{"%05d" % release.index}.#{release.format}"
  end

  def shownotes_name
    "#{@name}-#{release.date_string}-#{"%05d" % release.index}.html"
  end

  def full_dirname
    File.join @base_path, 'feeds', @serie
  end
  
  def shownotes_dirname
    File.join @base_path, 'shownotes', @serie
  end
  
  def full_filename
    File.join full_dirname, release_name
  end

  def shownotes_filename
    File.join shownotes_dirname, shownotes_name
  end
end

class ReleasePathByDate <ReleasePath

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

class ReleasePathInHeap <ReleasePath

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


class ReleasePath
    PATH_TYPES={
      :byname => ReleasePathByName,
      'byname'=> ReleasePathByName,
      :bydate => ReleasePathByDate,
      'bydate'=> ReleasePathByDate,
      :inheap => ReleasePathInHeap,
      'inheap'=> ReleasePathInHeap,
    }
end