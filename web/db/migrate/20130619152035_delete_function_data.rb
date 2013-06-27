class DeleteFunctionData < ActiveRecord::Migration
  def change

    drop_table :function_data
    
  end
end
