class VideosController < ApplicationController
  before_action :load_file, only: [:trim, :show]
  before_action :validate_file_size, only: [:create]
  before_action :validate_trim_params, only: [:trim]
  before_action :validate_merge_params, only: [:merge]

  def create
    video = Video.new(video_params)
    if video.save
    render json: { message: 'Video uploaded successfully', video: video }, status: :created
    else
    render json: { errors: video.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    key = SecureRandom.hex(16)
    $redis_client.set(key, @video.id, ex: DOWNLOAD_EXPIRY)
    render json: { video: @video, download_url: "#{request.base_url}/videos/download?video=#{key}" }, status: :ok
  end

  def trim
    video_params = {
      video: @video,
      start_time: params[:start_time].to_f,
      end_time: params[:end_time].to_f
    }
    result = VideoManipulator.new(video_params).trim
    if result
      render json: { message: 'Video trimmed successfully' }, status: :ok
    else
      render json: { error: 'Failed to trim video' }, status: :unprocessable_entity
    end
  end

  def merge
    result = VideoManipulator.new({ video1: @video1, video2: @video2 }).merge
    if result
      render json: { message: 'Videos merged successfully' }, status: :ok
    else
      render json: { error: 'Failed to merge videos' }, status: :unprocessable_entity
    end
  end

  def download
    key = params[:video]
    @video = Video.find_by_id($redis_client.get(key))
    if @video.nil?
      render json: { error: 'Video unavailable to download' }, status: :unprocessable_entity and return
    end
    attachment = @video.attachment
    if attachment.present?
      send_data attachment.download,
                filename: "#{@video.title}.mp4",
                content_type: attachment.content_type,
                disposition: 'attachment'
    else
      render json: { error: 'File not found' }, status: :not_found
    end
  end

  private

  def video_params
    params.require(:video).permit(:title, :file)
  end

  def validate_file_size
    uploaded_file = params[:video][:file]
    
    if uploaded_file
      file_size_in_mb = uploaded_file.size.to_f / 1.megabyte

      if file_size_in_mb > MAX_FILE_SIZE_MB
        render json: { error: "File is too large. Maximum allowed size is #{MAX_FILE_SIZE_MB} MB." }, status: :unprocessable_entity
      end
    else
      render json: { error: 'No file uploaded' }, status: :unprocessable_entity
    end
  end

  def load_file
    @video = Video.find_by_id(params[:id])

    if @video.nil?
      render json: { error: 'Video unavailable' }, status: :unprocessable_entity and return
    end
  end

  def validate_merge_params
    @video1 = Video.find_by(id: params[:video1_id])
    @video2 = Video.find_by(id: params[:video2_id])

    if @video1.nil? || @video2.nil?
      return render json: { error: 'One or both videos not found' }, status: :not_found
    end
  end

  def validate_trim_params
    start_time = params[:start_time].to_f
    end_time = params[:end_time].to_f

    if start_time < 0 || end_time <= start_time
      render json: { error: 'Invalid start_time or end_time' }, status: :unprocessable_entity and return
    end
  end
end
