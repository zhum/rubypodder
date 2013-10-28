class RubyPodRelease

  attr_accessor :name, :title, :content, :shownotes, :index, :state
  attr_accessor :format, :time, :url, :guid, :description, :mp3, :link
  attr_accessor :mp3link

  def initialize(n, u)
    @name=n
    @url=u
  end
  
  def has_shownotes?
    not :shownotes.nil?
  end

  def mark_loaded yes=true
    @loaded=yes
  end

  def date_string
    @time.strftime("%Y-%m-%d")
  end

  def loaded?
    @loaded
  end

  def agent
    @agent || 'RubyPodder'
  end

  def status
    @status
  end

  def set_status(s)
    @status=s
  end

  def download
    #return if already_downloaded(url, guid)
    #logger.info("  Downloading: #{url}")
    set_status :loading
    begin
      open(url, 'User-Agent' => agent) do |mp3|
        @content=mp3.read
      end
      mark_loaded
      set_status :loaded
    rescue => e
      #logger.error("  Failed to download #{url} (#{e.message})")
      set_status :error
      err_text="fail to download: #{e.message}"
    end
  end
end
