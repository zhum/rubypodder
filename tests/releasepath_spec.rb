require 'minitest/spec'
require 'minitest/autorun'
#require "minitest_helper"

require 'rubypodder'

describe ReleasePath do
  before do
  	@r=RubyPodRelease.new('release_name','tests/test.mp3')
    @r.name='my_release_name'
    @r.feed='fake feed'
  end

  describe "feed" do
    before do
      @r.feed='my feed'
      @p=ReleasePath.create(:byname,@r)
    end

	  it "has feed similar to release" do
	    @p.feed.must_equal 'my_feed'
	  end

    it "fixes feed with slashes and spaces in create" do
      @r.feed="ac/dc feedz"
      @p=ReleasePath.create(:byname,@r)
      @p.feed.must_equal 'ac_dc_feedz'
    end

    it "fixes feed with slashes and spaces in assigning" do
      @p=ReleasePath.create(:byname,@r)
      @p.feed="ac/dc feedz"
      @p.feed.must_equal 'ac_dc_feedz'
    end

    it "fixes empty feed" do
      @r.feed=''
      @p=ReleasePath.create(:byname,@r)
      @p.feed.must_equal 'unsorted'
    end

  end

  describe "name" do
    before do
      @p=ReleasePath.create(:byname,@r)
    end

    it "fixes empty name" do
      @r.name=''
      @p=ReleasePath.create(:byname,@r)
      @p.name.must_equal 'unnamed'
    end

    it "with type 'by name'" do
      @p.name.must_equal 'my_release_name'
    end

    it "fixes name with slashes and spaces in create" do
      @r.name="ac/dc rulez"
      @p=ReleasePath.create(:byname,@r)
      @p.name.must_equal 'ac_dc_rulez'
    end

    it "fixes name with slashes and spaces in assigning" do
      @p=ReleasePath.create(:byname,@r)
      @p.name="ac/dc rulez"
      @p.name.must_equal 'ac_dc_rulez'
    end
  end

  describe "paths" do
    describe "byname" do
      it 'full path is ~/.rubypodder/feeds/:feed/:name-:date-:index.:format' do
        @r.index=123
        @r.format='mp9'
        t=Time.now.strftime("%Y-%m-%d")
        @p=ReleasePath.create(:byname,@r)
        begin; File.delete File.expand_path("~/.rubypodder/feeds/fake_feed/my_release_name-#{t}-00123.mp9"); rescue; end
        @p.release_file("w") do |f|
          f.puts ""
        end
        File.file?(File.expand_path("~/.rubypodder/feeds/fake_feed/my_release_name-#{t}-00123.mp9")).must_equal true
      end
    end

    describe "bydate" do
      it 'full path is ~/.rubypodder/feeds/:date/:feed-:index-:name-:date.:format' do
        @r.index=123
        @r.format='mp9'
        t=Time.now.strftime("%Y-%m-%d")
        @p=ReleasePath.create(:bydate,@r)
        begin; File.delete File.expand_path("~/.rubypodder/feeds/#{t}/fake_feed-00123-my_release_name-#{t}.mp9"); rescue; end
        @p.release_file("w") do |f|
          f.puts ""
        end
        File.file?(File.expand_path("~/.rubypodder/feeds/#{t}/fake_feed-00123-my_release_name-#{t}.mp9")).must_equal true
      end
    end

    describe "inheap" do
      it 'full path is ~/.rubypodder/feeds/all/:feed-:index-:name-:date.:format' do
        @r.index=123
        @r.format='mp9'
        t=Time.now.strftime("%Y-%m-%d")
        @p=ReleasePath.create(:inheap,@r)
        begin; File.delete File.expand_path("~/.rubypodder/feeds/all/fake_feed-00123-my_release_name-#{t}.mp9"); rescue; end
        @p.release_file("w") do |f|
          f.puts ""
        end
        File.file?(File.expand_path("~/.rubypodder/feeds/all/fake_feed-00123-my_release_name-#{t}.mp9")).must_equal true
      end
    end
  end
end
