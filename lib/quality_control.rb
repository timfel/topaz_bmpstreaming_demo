module QualityControl
  FrameRate = 25
  FrameTime = 1.0 / 25
  LoadAvg = File.open("/proc/loadavg", "r")
  UserPref = File.open(File.expand_path("../../quality.pref", __FILE__), "r+")

  def self.included(base)
    base.instance_eval do
      @userpreference = 100
      @cpuload = 0
    end
  end

  def load
    LoadAvg.rewind
    cpuload = LoadAvg.read(4).gsub(".", "").to_i
  end

  def quality_control(quality)
    before = quality



    input = UserPref.read
    if @userpreference != input.to_i
      @userpreference = input.to_i
      quality = @userpreference
    end
    UserPref.truncate 0

    start = Time.now.to_f
    yield

    duration = Time.now.to_f - start
    LoadAvg.rewind
    cpuload_after = LoadAvg.read(4).gsub(".", "").to_i

    quality = (quality * (FrameTime / duration)).to_i
    if cpuload_after > cpuload
      quality -= (quality / 8)
    end

    puts "Quality changed: #{before} -> #{quality}" if quality != before
    return quality
  end
end
