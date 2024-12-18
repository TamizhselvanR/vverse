class AddAttachmentIdToVideos < ActiveRecord::Migration[8.0]
  def change
    add_column :videos, :attachment_id, :integer
  end
end
