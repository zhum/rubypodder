require 'rss'
require 'net/http'
require 'uri'
require 'rubygems'
require 'rio'
require 'logger'
require 'fileutils'
require 'forwardable'
require 'oj'

require 'rubypodrelease'
require 'releasepath'

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

##################################################
##################################################
##################################################

class PodFeedMetadata
  attr_accessor :name, :url, :date, :agent, :current_index
  attr_accessor :base_path, :store_strategy, :store_opts
end

class RubyPodFeed
  extend Forwardable

  attr_accessor :conf_file
  attr_reader   :metadata

  def_delegators :@metadata, :name, :url, :date, :agent, :current_index
  def_delegators :@metadata, :base_path, :store_strategy, :store_opts

  def_delegators :@metadata, :name=, :url=, :date=, :agent=, :current_index=
  def_delegators :@metadata, :base_path=, :store_strategy=, :store_opts=

  def initialize(the_name, conf=nil)
    default_init
    self.name=the_name
    #warn "Name=#{name}/#{@metadata.name}"
    @conf_file=conf
    @items={}
    self.store_opts ||= {}
  end
  
  def fetch_new
    log_update
    update_feed
    log_start
    items.each do |id,r|
      #warn r.inspect
      unless r.path.release_file?
        r.download
      end
    end
    log_end  
  end

  def update_feed
    begin
      http_body = open(self.url, 'User-Agent' => agent).read
      RSS::Parser.parse(http_body).items.each do |item|
        next unless item.enclosure
        next if @items.has_key? item.guid.content
        rel=RubyPodRelease.new(item.title, item.enclosure.url)
        if item.enclosure.url =~ /\.([^.]+)/
          rel.format=$1
        else
          rel.format='unknown'
        end
        rel.description=item.description
        rel.pubdate=item.pubDate
        rel.author=item.author
        rel.guid=item.guid.content
        rel.fresh=true
        rel.index=new_index
        rel.feed=self.name
        rel.base_path=self.base_path,
        rel.set_strategy(self.store_strategy, self.store_opts)
        rel.state=:not_loaded
        #rel.path=ReleasePath.create(rel.strategy, rel, :base_path => base_path)
        @items[rel.guid]=rel
      end
    #rescue  => e
    #  log_warn "Cannot update '#{self.name}': #{e.message}"
    #  warn "Cannot update '#{self.name}' (#{self.url}): #{e.message}"
    end

  end

  def releases
    @items
  end

  def items
    @items
  end

  def load_conf
    return default_init if(@conf_file.nil? || ! File.file?(@conf_file))
    @metadata=Oj.load_file(@conf_file)
    self
  end

  def save_conf
    return nil if @conf_file.nil?
    Oj.to_file(@conf_file,@metadata)
    true
  end

  def save_items
    return false if @conf_file.nil?
    File.open("#{@conf_file}.items", "w") { |file|
      str='{'+@items.map { |k,e| "#{Oj.dump(k.to_s)}:#{e.to_json}" }.join(',')+'}'
      file.puts str
    }
    true
  end

  def load_items
    return false if @conf_file.nil? || (not File.exist?("#{@conf_file}.items"))
    new_items=Oj.load_file("#{@conf_file}.items")
    max_index=self.current_index
    #warn "Loaded #{new_items.class}"
    new_items.each do |k,v|
      #warn "Restoring #{k} -> #{v}"
      @items[k]=RubyPodRelease.new(v)
      max_index = [max_index,@items[k].index].max
    end
    self.current_index=max_index
    true
  end

private

  def default_init
    @metadata=PodFeedMetadata.new
    self.current_index=0
    self.agent='RubyPodder'
    self.store_strategy=:byname
    self.base_path=File.expand_path('~/.rubypodder')
    self
  end

  def new_index
    self.current_index ||= 0
    self.current_index+=1
  end

  def log_start
  end

  def log_end
  end

  def log_update
  end

  def log_warn message
  end
end


if $0 == __FILE__
  RubyPodder.new.run
end

__END__
title
link
description
category
source
enclosure
comments
author
pubDate
date
guid
content_encoded
dc_title
dc_descriptions
dc_creator
dc_subjects
dc_subject
dc_publishers
dc_publisher
dc_contributors
dc_contributor
dc_types
dc_type
dc_formats
dc_format
dc_identifiers
dc_identifier
dc_sources
dc_source
dc_coverages
dc_coverage
dc_rights_list
dc_rights
dc_dates
dc_date
itunes_author
itunes_block
itunes_keywords
itunes_keywords_content
itunes_subtitle
itunes_summary
itunes_name
itunes_email
itunes_duration
parent
tag_name
full_name
