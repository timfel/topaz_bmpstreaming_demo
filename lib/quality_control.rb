module QualityControl
  FrameRate = 12
  FrameTime = 1.0 / FrameRate
  LoadAvg = File.open("/proc/loadavg", "r")
  UserPref = File.open(File.expand_path("../../quality.pref", __FILE__), "r+")

  def self.extended(base)
    base.instance_eval do
      @user_preference = 100
      @cpuload = 0
      @duration = FrameTime
    end
  end

  def read_cpu_load
    LoadAvg.rewind
    @cpuload = LoadAvg.read(4).gsub(".", "").to_i
  end

  def read_user_preference
    input = UserPref.read
    if input and input.size > 0
      UserPref.truncate 0
      @user_preference = input.to_i
    end
  end

  def read_system_stats
    read_cpu_load
    read_user_preference
  end

  def cpuload
    @cpuload
  end

  def user_preference
    @user_preference
  end

  def duration
    @duration
  end

  def quality_control
    read_system_stats
    start = Time.now.to_f
    yield
    @duration = Time.now.to_f - start
    @quality = recalculate_quality
  end

  def recalculate_quality
    # require "rubygems"; require 'ruby-debug';debugger
    quality = @quality

    # First, adjust quality based on encoding speed
    if FrameTime > duration * 1.5
      # We're pretty fast, adjust quality upwards
      quality = quality * (FrameTime / duration)
    elsif FrameTime < duration * 1.5
      # We were too slow, adjust
      quality = quality * (FrameTime / duration)
    end

    if cpuload > 80 and duration * 1.5 > FrameTime
      # The load is pretty high and we're not that fast, go down a bit
      quality = quality * (cpuload - 80) / 100.0
    end

    # User preference is least important, and should only be
    # considered if we can handle the load
    if quality > user_preference
      quality = user_preference
    end

    # Try do go down gently
    if quality < @quality - @quality.to_f / 32
      quality = @quality - @quality.to_f / 32
    end

    quality.to_i
  end
end
