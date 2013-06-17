class CreateFunctionData < ActiveRecord::Migration
  def change
    create_table :function_data do |t|
      t.string :ref
      t.references :user, index: true
      t.string :check_block
      t.string :definition
      t.string :header

      t.timestamps
    end
  end
end
