class CreateCodeRunEvents < ActiveRecord::Migration
  def change
    create_table :code_run_events do |t|
      t.text :data

      t.timestamps
    end
  end
end
