module QualityControl
  FrameRate = 12
  FrameTime = 1.0 / FrameRate
  UserPref = File.open(File.expand_path("../../quality.pref", __FILE__), "r+")

  def self.extended(base)
    base.instance_eval do
      @user_preference = 100
      @cpuload = 0
      @duration = FrameTime
    end
  end

  def read_user_preference
    input = UserPref.read
    if input and input.size > 0
      UserPref.seek 0, File::SEEK_SET
      @user_preference = input.to_i
    end
  end

  def read_system_stats
    read_user_preference
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
    # Adjust quality based on encoding speed of last frame
    if FrameTime > duration
      @quality = @quality * (FrameTime * 2 / duration)
    elsif FrameTime < duration * 0.9
      @quality = @quality * (FrameTime / duration)
    end

    # User preference is only upper bound
    if @quality > user_preference
      @quality = user_preference
    end

    # Round to nearest int
    @quality = @quality.to_i
  end
end
