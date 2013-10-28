require 'minitest/spec'
require 'minitest/autorun'
require "minitest_helper"

require 'rubypodder'

describe RubyPodRelease do
  before do
  	@r=RubyPodRelease.new('name','tests/test.mp3')
  end

  describe "release abilities" do
	  it "has name" do
	    @r.name.must_equal 'name'
	  end
	end

	describe "download possibilities" do
	  before do
	  	@r.download
	  end
	  it "loads mp3" do
	    mp3=File.read('tests/test.mp3')
	    @r.content.must_equal mp3
	  end
	  it "loaded status is :loaded" do
	    x=@r.status
	    x.must_equal :loaded
	  end
	  it "loaded is loaded" do
	    @r.loaded?.must_equal true
	  end
	end

	describe "download errors handled" do
    before(:each) do
    	@r.url='bad.mp3'
    	@r.download
    end

	  it "has nil content" do
	  	@r.content.must_be_nil
	  end

	  it "status is error" do
	  	@r.status.must_equal :error
	  end
	end

end
