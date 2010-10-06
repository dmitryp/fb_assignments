class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.datetime  :start_at
      t.datetime  :end_at
      t.string    :status
      t.text      :notes
      t.string    :first_name
      t.string    :last_name
      t.string    :email
      t.string    :phone
      t.string    :mobile
      t.string    :fax
      
      t.string    :address1
      t.string    :address2
      t.string    :city
      t.string    :state
      t.string    :zip
      t.string    :country
      t.string    :inquiry_source
      
      t.integer :num_adults, :default => 0
      t.integer :num_children, :default => 0
      
      t.string :remote_id
      t.integer :listing_id
      t.integer :user_id
      
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assignments
  end
end
