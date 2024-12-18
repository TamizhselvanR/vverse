class VideosController < ApplicationController
  def create
    video = Video.new(video_params.except(:file))
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
end
