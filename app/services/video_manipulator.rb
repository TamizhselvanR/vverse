class VideoManipulator
  def initialize(params)
    @params = params
  end

  def trim
    @video = @params[:video]
    @start_time = @params[:start_time]
    @end_time = @params[:end_time]
    if @start_time < 0 || @end_time > @video.duration || @end_time <= @start_time
      raise ArgumentError, "Invalid start or end times"
    end

    attachment = @video.attachment

    temp_file_path = save_to_temp_file(attachment, "pre_trim_#{Time.now.to_i}")
    movie = FFMPEG::Movie.new(temp_file_path.to_s)

    output_path = Rails.root.join('tmp', 'videos', "trimmed_#{Time.now.to_i}_#{attachment.filename.to_s}")
    options = {
      custom: %W[-ss #{@start_time} -to #{@end_time} -c copy]
    }

    movie.transcode(output_path.to_s, options)
    save_trimmed_video(attachment, output_path)
  rescue => e
    Rails.logger.error("Video trimming failed: #{e.message}")
    nil
  ensure
    File.delete(output_path) if output_path.present? && File.exist?(output_path)
  end

  def merge
    @video1 = @params[:video1]
    @video2 = @params[:video2]
    video1_path = save_to_temp_file(@video1.attachment, "vid1_#{Time.now.to_i}")
    video2_path = save_to_temp_file(@video2.attachment, "vid2_#{Time.now.to_i}")
    output_path = Rails.root.join('tmp', 'videos', "merged-#{Time.now.to_i}#{@video1.id}#{@video2.id}.mp4")
    preprocess_and_concat(video1_path, video2_path, output_path)
    video = Video.new(
      title: "merged video - #{@video1.id} & #{@video1.id}",
      file: File.open(output_path),
      content_type: 'video/mp4'
    )
    video.save
    video
  rescue => e
    Rails.logger.error("Video merging failed: #{e.message}")
    nil
  end

  private

  def save_to_temp_file(attachment, prefix)
    temp_file_path = Rails.root.join('tmp', 'videos', "#{prefix}_#{attachment.filename.to_s}")
    attachment.download do |file_content|
      File.open(temp_file_path, 'wb') do |file|
        file.write(file_content)
      end
    end
    temp_file_path
  end

  def save_trimmed_video(attachment, path)
    # Added transaction such that even if new video update failed
    # old attachment won't gets deleted
    ActiveRecord::Base.transaction do
      blob = create_video(attachment.filename, attachment.content_type, path)
      attachment.destroy
      @video.attachment_id = blob.id
      @video.duration = @end_time - @start_time
      @video.save(validate: false)
    end
  end

  def create_video(name, type, path)
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(path),
      filename: name,
      content_type: type,
      identify: false
    )
  end

  def preprocess_and_concat(video1_path, video2_path, output_path)
    temp_dir = Rails.root.join('tmp', 'videos')

    # Re-encode videos to a common format
    movie1 = FFMPEG::Movie.new(video1_path.to_s)
    movie1_path = temp_dir.join("video1_pre_#{Time.now.to_i}.mp4")
    movie1.transcode(movie1_path.to_s, { video_codec: "libx264" })
  
    movie2 = FFMPEG::Movie.new(video2_path.to_s)
    movie2_path = temp_dir.join("video2_pre_#{Time.now.to_i}.mp4")
    movie2.transcode(movie2_path.to_s, { video_codec: "libx264" })
  
    # Then concatenate the re-encoded files
    concatenate_videos([movie1_path, movie2_path], output_path)
  end

  def concatenate_videos(video_paths, output_path)
    temp_dir = Rails.root.join('tmp', 'videos')
  
    concat_file = temp_dir.join("concat.txt")
    File.open(concat_file, 'w') do |f|
      video_paths.each do |video_path|
        f.puts("file '#{video_path}'")
      end
    end
  
    # Run FFmpeg concat command
    system("ffmpeg -f concat -safe 0 -i #{concat_file} -c copy -f mp4 #{output_path}")
  end
end
