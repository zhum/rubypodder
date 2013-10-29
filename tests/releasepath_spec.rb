require 'minitest/spec'
require 'minitest/autorun'
#require "minitest_helper"

require 'rubypodder'

describe ReleasePath do
  before do
  	@r=RubyPodRelease.new('release_name','tests/test.mp3')
    @r.name='my_release_name'
    @r.serie='fake serie'
  end

  describe "serie" do
    before do
      @r.serie='my serie'
      @p=ReleasePath.create(:byname,@r)
    end

	  it "has serie similar to release" do
	    @p.serie.must_equal 'my_serie'
	  end

    it "fixes serie with slashes and spaces in create" do
      @r.serie="ac/dc seriez"
      @p=ReleasePath.create(:byname,@r)
      @p.serie.must_equal 'ac_dc_seriez'
    end

    it "fixes serie with slashes and spaces in assigning" do
      @p=ReleasePath.create(:byname,@r)
      @p.serie="ac/dc seriez"
      @p.serie.must_equal 'ac_dc_seriez'
    end

    it "fixes empty serie" do
      @r.serie=''
      @p=ReleasePath.create(:byname,@r)
      @p.serie.must_equal 'unsorted'
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
      it 'full path is ~/.rubypodder/feeds/:serie/:name-:date-:index.:format' do
        @r.index=123
        @r.format='mp9'
        t=Time.now.strftime("%Y-%m-%d")
        @p=ReleasePath.create(:byname,@r)
        begin; File.delete "~/.rubypodder/feeds/fake_serie/my_release_name-#{t}-00123.mp9"; rescue; end
        @p.release_file("w") do |f|
          f.puts ""
        end
        File.file?(File.expand_path("~/.rubypodder/feeds/fake_serie/my_release_name-#{t}-00123.mp9")).must_equal true
      end
    end

    describe "bydate" do
      
    end

    describe "inheap" do

    end
  end
end
