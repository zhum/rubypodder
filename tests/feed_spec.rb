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
  end

  describe "saves and loads state" do
    before do
      @r.conf_file='/tmp/test_config'
    end

    it 'saves state and restores it' do
      @r.save_conf
      @r.url='new.url'
      @r.load_conf
      @r.url.must_equal 'tests/test.xml'
    end

    it 'saves items and restores them' do
      @r.update_feed
      @r.save_items
      @r2=RubyPodFeed.new('second feed')
      @r2.conf_file='/tmp/test_config'
      @r2.load_items
      @r2.releases.count.must_equal 11
    end

  end
end
