module QualityControl
  FrameRate = 25
  FrameTime = 1000 / 25
  LoadAvg = File.open("/proc/loadavg", "r")

  def quality_control(quality)

    LoadAvg.rewind
    cpuload = LoadAvg.read(4).gsub(".", "").to_i

    start = Time.now.to_f
    yield
    duration = Time.now.to_f - start

    LoadAvg.rewind
    cpuload_after = LoadAvg.read(4).gsub(".", "").to_i

    # Very important: stay fast
    if duration > FrameTime
      quality = quality * (FrameTime / duration)
    end

    return quality
  end
end
