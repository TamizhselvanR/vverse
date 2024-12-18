class Video < ApplicationRecord

  attr_accessor :file
  belongs_to :attachment, class_name: 'ActiveStorage::Attachment', optional: true

  validates :title, presence: true
  validate :validate_file_size
  before_save :update_attachment

  private

  def update_attachment
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type,
      identify: false
    )
    self.attachment_id = blob.id
    video = FFMPEG::Movie.new(file.download)
    self.duration = video.duration.to_i
  end

  def validate_file_size
    if file.present? && file.size > MAX_FILE_SIZE_MB.megabytes
      errors.add(:file, "is too large. Maximum size allowed is 25 MB.")
    end
  end
end
