require 'minitest/spec'
require 'minitest/autorun'
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
	    @r.releases.count.must_equal 11
  	end

    it 'loads missed mp3' do
      @r.items.delete('<guid isPermaLink=\"false\">http://www.rwpod.com/posts/2013/10/20/podcast-01-31.html</guid>')
      system "rm -rf ~/.rubypodder/feeds"
      @r.current_index=555
      @r.fetch_new
      warn ">>>>>>>>>>>>>>>>>>>>>>"
      system "ls -R ~/.rubypodder"
      warn "<<<<<<<<<<<<<<<<<<<<<<"
      File.exist?(File.expand_path("~/.rubypodder/feeds/fake_feed/my_release_name-2013-11-20-00555.mp3")).must_equal true
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
      @r2.releases.count.must_equal 11
    end

  end
end
