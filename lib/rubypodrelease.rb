class RubyPodRelease

  attr_accessor :name, :title, :content, :shownotes, :index, :feed
  attr_accessor :format, :time, :url, :guid, :description, :mp3, :link
  attr_accessor :author, :pubdate
  attr_accessor :mp3link, :state, :fresh, :base_path, :err_text
  attr_reader :path

  def initialize(n, u='')
    if n.kind_of? Hash
      n.each do |k,v|
        instance_variable_set(k,v)
      end
      set_strategy(self.strategy)
    else
      @name=n
      @url=u
      @time = @pubdate = Time.now
      @state = :not_initialized
      set_strategy(:byname)
    end
  end
  
  def to_json
    str=instance_variables.map do |i|
      v=instance_variable_get(i)
      #warn "Saving '#{i} (#{v.class}): #{v.inspect}"
      [String,Fixnum,Bignum,Symbol,TrueClass,FalseClass,Time].include?(v.class) ?
        Oj.dump({i=>v})[1..-2] :
        nil
    end.reject{|x| x.nil?}.join(",\n  ")
    "{#{str}}\n"
  end

  def to_s
    "Feed: #{@feed}\nTitle: #{@title}\n GUID=#{@guid}; Index=#{@index}; Date=#{@pubdate}
  State=#{@state}; Path to mp3: #{@path.release_name} (#{File.file?(@path.release_name) ? '': 'not '}loaded)"
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

  def set_strategy(s, opts={})
    @strategy=s
    opts[:base_path] = @base_path
    @path=ReleasePath.create(s, self, opts )
  end

  def download
    #return if already_downloaded(url, guid)
    #logger.info("  Downloading: #{url}")
    set_status :loading
    begin
      open(url, 'User-Agent' => agent) do |mp3stream|
        @path.release_file("w") do |mp3file|
          #warn "Loading #{mp3file.inspect}"
          rio(mp3stream) > rio(mp3file)
        end
      end
      mark_loaded
      set_status :loaded
    rescue => e
      #warn("  Failed to download #{url} (#{e.message})")
      set_status :error
      @err_text="fail to download: #{e.message}"
    end
  end
end
