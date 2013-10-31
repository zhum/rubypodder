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
  attr_reader :release, :name, :feed, :base_path

  DEFAULT_BASE=File.expand_path('~/.rubypodder')

  def self.create(type, release, opts={})
    PATH_TYPES[type].new(release,opts) || raise("Bad path type type: #{type}")
  end

  def name= str
    @name=fix_name(str)
  end

  def feed= str
    @feed=fix_name(str)
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

  def full_filename
    File.join full_dirname, release_name
  end

  def shownotes_filename
    File.join shownotes_dirname, shownotes_name
  end

private

  def initialize(release, opts={})
    @release=release
    @feed = fix_name(@release.feed) || 'unsorted'
    @name  = fix_name(@release.name) || 'unnamed'
    @base_path = opts[:base_path] || DEFAULT_BASE
    @opts=opts
  end

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
    File.join @base_path, 'feeds', @feed
  end
  
  def shownotes_dirname
    File.join @base_path, 'shownotes', @feed
  end
  
end

class ReleasePathByDate <ReleasePath

  def release_name
    "#{@feed}-#{"%05d" % release.index}-#{@name}-#{release.date_string}.#{release.format}"
  end

  def shownotes_name
    "#{@feed}-#{"%05d" % release.index}-#{@name}-#{release.date_string}.html"
  end

  def full_dirname
    File.join @base_path, 'feeds', release.date_string
  end
  
  def shownotes_dirname
    File.join @base_path, 'shownotes', release.date_string
  end
end

class ReleasePathInHeap <ReleasePath

  def release_name
    "#{feed}-#{"%05d" % release.index}-#{@name}-#{release.date_string}.#{release.format}"
  end

  def shownotes_name
    "#{feed}-#{"%05d" % release.index}-#{@name}-#{release.date_string}.html"
  end

  def full_dirname
    File.join @base_path, 'feeds', 'all'
  end
  
  def shownotes_dirname
    File.join @base_path, 'shownotes', 'all'
  end
end

class ReleasePathCustom <ReleasePath

  def filter x
    x.gsub('/','_')
    fix_name x
  end

  def release_name
    pattern2name @pattern
  end

  def shownotes_name
    pattern2name @shownotes_name
  end

  def pattern2name name
    name.gsub(/%\{([a-z_]+)\}/){|match|
      filter case(match)
      when '%{feed}'
        @release.feed.to_s
      when '%{title}'
        @release.title.to_s
      when '%{name}'
        @release.name.to_s
      when '%{index}'
        "%05d" % @release.index.to_s
      when '%{date}'
        @release.pubdate.to_s
      when '%{year}'
        '%04d' % @release.pubdate.year
      when '%{month}'
        '%02d' % @release.pubdate.month
      when '%{day}'
        '%02d' % @release.pubdate.day
      when '%{format}'
        @release.format.to_s
      when '%{author}'
        @release.author.to_s
      else
        "%{#{match}}"
      end
    }
  end

  def full_dirname
    File.join @base_path, 'feeds'
  end
  
  def shownotes_dirname
    File.join @base_path, 'shownotes'
  end

  def initialize(release, opts={})
    super
    @pattern=opts[:pattern] || 'NO PATTERN'
    @shownotes_pattern=opts[:shownotes_pattern] || 'NO PATTERN'
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
      :custom => ReleasePathCustom,
      'custom'=> ReleasePathCustom,
    }
end