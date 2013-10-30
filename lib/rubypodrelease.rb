class RubyPodRelease

  attr_accessor :name, :title, :content, :shownotes, :index, :feed
  attr_accessor :format, :time, :url, :guid, :description, :mp3, :link
  attr_accessor :author, :pubdate
  attr_accessor :mp3link, :state, :fresh, :path, :base_path, :err_text

  def initialize(n, u='')
    if n.kind_of? Hash
      n.each do |k,v|
        instance_variable_set(k,v)
      end
      self.strategy=self.strategy
    else
      @name=n
      @url=u
      @time = @pubdate = Time.now
      @state = :not_initialized
      self.strategy = :byname
    end
  end
  
  def to_json
    str=instance_variables.map do |i|
      v=instance_variable_get(i)
      [String,Array,Fixnum,Bignum,Symbol].include?(v.class) ?
        Oj.dump({i=>v})[1..-2] :
        nil
    end.reject{|x| x.nil?}.join(",\n  ")
    "{#{str}}\n"
  end

  def has_shownotes?
    not :shownotes.nil?
  end

  def mark_loaded yes=true
    @loaded=yes
  end

  def date_string
    @pubdate.strftime("%Y-%m-%d")
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

  def strategy
    @strategy
  end

  def strategy= s
    @strategy=s
    @path=ReleasePath.create(s, self, :base_path => @base_path)
  end

  def download
    #return if already_downloaded(url, guid)
    #logger.info("  Downloading: #{url}")
    set_status :loading
    begin
      open(url, 'User-Agent' => agent) do |mp3stream|
        @path.release_file("w") do |mp3file|
          rio(mp3stream) > rio(mp3file)
        end
      end
      mark_loaded
      set_status :loaded
    rescue => e
      warn("  Failed to download #{url} (#{e.message})")
      set_status :error
      @err_text="fail to download: #{e.message}"
    end
  end
end
