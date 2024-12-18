class Video < ApplicationRecord
  has_one_attached :file

  validates :title, presence: true
  # validates :file, attached: true, content_type: ['video/mp4', 'video/mov'], size: { less_than: 25.megabytes } # Configurable size
  # validates :duration, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 300 } # Configurable duration

  before_validation :extract_metadata, if: -> { file.attached? }

  private

  def extract_metadata
    video = FFMPEG::Movie.new(file.download)
    self.duration = video.duration.to_i
  end
end