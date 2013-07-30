class RenameSubmittedTypeToSubmissionType < ActiveRecord::Migration
  def change
    rename_column :submitteds, :type, :submission_type    
  end
end
