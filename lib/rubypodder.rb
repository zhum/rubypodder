require 'rss'
#require 'rss/2.0'
require 'net/http'
require 'uri'
require 'rubygems'
require 'rio'
require 'logger'
require 'ftools'

class File

  def self.touch(fn)
    File.open(fn, "w").close unless File.exist?(fn)
  end

end

class RubyPodder

  Version = 'rubypodder v2.0.0'

  attr_reader :conf_file, :log_file, :done_file, :date_dir

  def initialize(file_base="~/.rubypodder/rp")
    @file_base = File.expand_path(file_base)
    @rp_dir = File.dirname(@file_base)
    @conf_file = @file_base + ".conf"
    @log_file = @file_base + ".log"
    @done_file = @file_base + ".done"
    create_default_config_file
    @log = Logger.new(@log_file)
    File.touch @done_file
    @date_dir = create_date_dir
  end

  def create_default_config_file
    expanded_path = File.expand_path(@conf_file)
    return if File.exists?(expanded_path)
    make_dirname(expanded_path)
    rio(expanded_path) < "http://downloads.bbc.co.uk/rmhttp/downloadtrial/radio4/thenowshow/rss.xml\n"
  end

  def make_dirname(full_filename)
    dirname = File.dirname(full_filename)
    File.makedirs dirname
  end

  def date_string(time)
    time.strftime("%Y-%m-%d")
  end

  def create_date_dir
    date_dir = File.join(@rp_dir, date_string(Time.now))
    File.makedirs date_dir
    date_dir
  end

  def read_feeds
    #IO.readlines(@conf_file).each {|l| l.chomp!}
    rio(@conf_file).chomp.readlines.reject {|i| i =~ /^#/ || i =~ /^\s*$/}
  end

  def parse_rss(rss_source)
    RSS::Parser.parse(rss_source, false)
  end

  def dest_file_name(url)
    dest = File.join(@date_dir, File.basename(URI.parse(url).path))
    dest = dest.gsub(/\s+/,'_').gsub('%20','_')
    while File.exists? dest
      ext = File.extname(dest)
      name = File.basename(dest, ext)
      name += "_00" unless name =~ /_\d+$/
      name.succ!
      dest = File.join(File.dirname(dest), name + ext)
    end
    return dest
  end

  def record_download(url, guid)
    if guid
      rio(@done_file) << "#{guid}\n"
    end
    rio(@done_file) << "#{url}\n"
  end

  def already_downloaded(url, guid)
    if guid
      previously_downloaded = [url.strip.downcase, guid.strip.downcase]
      File.open(@done_file).detect do |line|
        previously_downloaded.include?(line.strip.downcase)
      end
    else
      File.open(@done_file).detect do |line|
        url.strip.downcase == line.strip.downcase
      end
    end

  end

  def download(url, guid)
    return if already_downloaded(url, guid)
    @log.info("  Downloading: #{url}")
    begin
      file_name = dest_file_name(url)
      rio(file_name) < rio(url)
    rescue
      @log.error("  Failed to download #{url}")
      File.delete(file_name) if File.exists?(file_name)
    else
      record_download(url, guid)
    end
  end

  def download_all(items)
    items.each do |item|
      begin
        guid = nil
        if item.respond_to?(:guid) && item.guid.respond_to?(:content)
          guid = item.guid.content
        end
        download(item.enclosure.url, guid)
      rescue
        @log.warn("  No media to download for this item")
      end
    end
  end

  def remove_dir_if_empty(dirname)
    begin
      Dir.rmdir(dirname)
    rescue SystemCallError
      @log.info("#{dirname} has contents, not removed")
    else
      @log.info("#{dirname} was empty, removed")
    end
  end

  def run
    @log.info("Starting (#{Version})")
    read_feeds.each do |url|
      begin
        http_body = open(url, 'User-Agent' => 'Ruby-Wget').read
      rescue
        @log.error("  Can't read from #{url}")
        next
      end
      begin
        rss = parse_rss(http_body)
      rescue
        @log.error("  Can't parse this feed")
        next
      end
      @log.info("Channel: #{rss.channel.title}")
      download_all(rss.items)
    end
    remove_dir_if_empty(@date_dir)
    @log.info("Finished")
  end

end

class RubyPodFeed
  attr_accessor :conf_file, :name

  def initialize(name)
    @name=name
    @conf_file=nil
    default_init
  end
  
  def fetch_new
    log_start
    log_end  
  end

  def list_releases
    
  end

  def load_conf
    return default_init if @conf_file.nil?

  end

  def save_conf
    return nil if @conf_file.nil?

  end

private

  def default_init
    @saver=RubyPodSaverByName.new(@name)
  end

  def log_start
    
  end

  def log_end
  end
end

class RubyPodRelease

  attr_accessor :name

  def initialize(name)
    @name=name
  end
  
  def status
    
  end
  
end

class RubyPodSaver
  attr_reader :name

  DEFAULT_BASE=File.expand_path('~/.rubypodder')

  def initialize(new_name, opts={})
    self.name=new_name
    @base_path=opts[:base_path] || DEFAULT_BASE
  end

  def name= name
    @name = name.gsub(/[/\\\0 ]+/, '_')
  end

  def save(release)
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
    "#{release.date_string}-#{release.index}.#{release.format}"
  end

  def shownotes_name
    "#{release.date_string}-#{release.index}.html"
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


if $0 == __FILE__
  RubyPodder.new.run
end
