class Video < ApplicationRecord

  attr_accessor :file
  belongs_to :attachment, class_name: 'ActiveStorage::Attachment', optional: true

  before_validation :update_attachment

  validates :title, presence: true
  validate :validate_file_size
  validate :validate_content_type
  # validates :duration, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: 300 }

  private

  def update_attachment
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type,
      identify: false
    )
    self.attachment_id = blob.id
  end

  def validate_file_size
    if file.present? && file.size > MAX_FILE_SIZE_MB.megabytes
      errors.add(:file, "is too large. Maximum size allowed is 25 MB.")
    end
  end

  def validate_content_type
    if file.present? && ALLOWED_VIDEO_CONTENT_TYPES.exclude?(file.content_type)
      errors.add(:file, "has an invalid content type. Allowed types are: #{ALLOWED_VIDEO_CONTENT_TYPES.join(', ')}.")
    end
  end
end
