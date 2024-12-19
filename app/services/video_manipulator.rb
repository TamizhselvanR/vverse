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
    temp_file_path = Rails.root.join('tmp', 'videos', "pre_trim_#{attachment.filename.to_s}")
    attachment.download do |file_content|
      File.open(temp_file_path, 'wb') do |file|
        file.write(file_content)
      end
    end
    movie = FFMPEG::Movie.new(temp_file_path.to_s)

    output_path = Rails.root.join('tmp', 'videos', "trimmed_#{attachment.filename.to_s}")
    options = {
      custom: %W[-ss #{@start_time} -to #{@end_time} -c copy]
    }

    movie.transcode(output_path.to_s, options)
    save_trimmed_video(movie, attachment, output_path)
  rescue => e
    Rails.logger.error("Video trimming failed: #{e.message}")
    nil
  end

  private

  def save_trimmed_video(movie, attachment, output_path)
    # Added transaction such that even if new video update failed
    # old attachment won't gets deleted
    ActiveRecord::Base.transaction do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(output_path),
        filename: attachment.filename,
        content_type: attachment.content_type,
        identify: false
      )
      attachment.destroy
      @video.attachment_id = blob.id
      @video.duration = @end_time - @start_time
      @video.save(validate: false)
    end
  ensure
    File.delete(output_path) if File.exist?(output_path)
  end
end
