require 'rss/1.0'
require 'rss/2.0'
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

  Version = 'rubypodder v1.0.0'

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
    a = rio(@conf_file).chomp.readlines.reject {|i| i =~ /^#/}
  end

  def parse_rss(rss_source)
    RSS::Parser.parse(rss_source, false)
  end

  def dest_file_name(url)
    File.join(@dest_dir, File.basename(URI.parse(url).path))
  end

  def record_download(url)
    rio(@done_file) << "#{url}\n"
  end

  def already_downloaded(url)
    url_regexp = Regexp.new(url)
    File.open(@done_file).grep(url_regexp).length > 0
  end

  def download(url)
    return if already_downloaded(url)
    @log.info("  Downloading: #{url}")
    begin
      file_name = dest_file_name(url)
      rio(file_name) < rio(url)
    rescue
      @log.error("  Failed to download #{url}")
    else
      record_download(url)
    end
  end

  def download_all(items)
    items.each do |item|
      begin
        download(item.enclosure.url)
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

if $0 == __FILE__
  RubyPodder.new.run
end
