class VideosController < ApplicationController

  before_action :validate_file_size, only: [:create]

  def create
    video = Video.new(video_params)
    if video.save
    render json: { message: 'Video uploaded successfully', video: video }, status: :created
    else
    render json: { errors: video.errors.full_messages }, status: :unprocessable_entity
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
end
