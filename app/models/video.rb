class Video < ApplicationRecord

  attr_accessor :file, :content_type
  belongs_to :attachment, class_name: 'ActiveStorage::Blob', optional: true

  before_validation :update_attachment

  validates :title, presence: true
  validate :validate_file_size
  validate :validate_content_type
  validates :duration, numericality: { greater_than_or_equal_to: MIN_DURATION, less_than_or_equal_to: MAX_DURATION }

  private

  def update_attachment
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: "#{title}.mp4",
      content_type: content_type || file.content_type,
      identify: false
    )
    self.attachment_id = blob.id
    temp_dir = Rails.root.join('tmp', 'videos')
    temp_file_path = temp_dir.join(blob.filename.to_s)
    attachment.download do |file_content|
      File.open(temp_file_path, 'wb') do |file|
        file.write(file_content)
      end
    end
    vid = FFMPEG::Movie.new(temp_file_path.to_s)
    self.duration = vid.duration
  end

  def validate_file_size
    if file.present? && file.size > MAX_FILE_SIZE_MB.megabytes
      errors.add(:file, "is too large. Maximum size allowed is 25 MB.")
    end
  end

  def validate_content_type
    if file.present? && ALLOWED_VIDEO_CONTENT_TYPES.exclude?(content_type || file.content_type)
      errors.add(:file, "has an invalid content type. Allowed types are: #{ALLOWED_VIDEO_CONTENT_TYPES.join(', ')}.")
    end
  end
end
