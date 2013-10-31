#
# encoding: utf-8
require 'minitest/spec'
require 'minitest/autorun'
require "webmock/minitest"
#require "minitest_helper"

require 'rubypodder'

describe RubyPodFeed do
  before do
  	@r=RubyPodFeed.new('test feed name')
    @r.url='tests/test.xml'
  end

  describe "release abilities" do
	  it "has name" do
	    @r.name.must_equal 'test feed name'
	  end

	  it "loads all items" do
      @r.update_feed
	    @r.releases.count.must_equal 2
  	end

    it 'loads missed mp3' do
      stub_request(:any, %r/.*podfm.*/).to_return(:body => "mp3 content")

      @r.fetch_new
      @r.items.map { |e| warn e.to_s }
      @r.items.delete('http://www.rwpod.com/posts/2013/10/20/podcast-01-31.html')
      system "rm -f ~/.rubypodder/feeds/test_feed_name/31S01-2013-10-20-*"
      @r.current_index=555
      @r.update_feed
      @r.fetch_new
      warn ">>>>>>>>>>>>>>>>>>>>>>"
      @r.items.each { |k,e| warn e.to_s }
#      system "ls -R ~/.rubypodder >&2"
      warn "<<<<<<<<<<<<<<<<<<<<<<"
      File.exist?(File.expand_path("~/.rubypodder/feeds/test_feed_name/31S01-2013-10-20-00001.mp3")).must_equal true
    end
  end

  describe "saves and loads state" do
    before do
      @r.conf_file='/tmp/test_config'
    end

    it 'saves state to file and restores it' do
      @r.save_conf
      @r.url='new.url'
      @r.load_conf
      @r.url.must_equal 'tests/test.xml'
    end

    it 'saves items to file and restores them' do
      @r.update_feed
      @r.save_items
      @r2=RubyPodFeed.new('second feed')
      @r2.conf_file='/tmp/test_config'
      @r2.load_items
      @r2.releases.count.must_equal 2
    end

  end
end
