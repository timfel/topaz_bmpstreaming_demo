module QualityControl
  FrameRate = 25
  FrameTime = 1.0 / 25
  LoadAvg = File.open("/proc/loadavg", "r")

  def self.included(base)
    base.instance_eval do
      @userpreference = 100
    end
  end

  def quality_control(quality)
    LoadAvg.rewind
    cpuload = LoadAvg.read(4).gsub(".", "").to_i
    start = Time.now.to_f

    yield

    duration = Time.now.to_f - start
    LoadAvg.rewind
    cpuload_after = LoadAvg.read(4).gsub(".", "").to_i

    begin
      input = $stdin.read_nonblock(5)
      if @userpreference != input.to_i
        @userpreference = input.to_i
        quality = @userpreference
      end
    rescue IO::WaitReadable
    end

    quality = (quality * (FrameTime / duration)).to_i
    if cpuload_after > cpuload
      quality -= 5
    end

    return quality
  end
end
