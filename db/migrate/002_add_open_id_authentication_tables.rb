class AddOpenIdAuthenticationTables < ActiveRecord::Migration
  def self.up
    create_table :open_id_authentication_associations, :force => true do |t|
      t.column :server_url, :binary
      t.column :handle, :string
      t.column :secret, :binary
      t.column :issued, :integer
      t.column :lifetime, :integer
      t.column :assoc_type, :string
    end

    create_table :open_id_authentication_nonces, :force => true do |t|
      t.column :timestamp, :integer, :null => false
      t.column :server_url, :string, :null => true
      t.column :salt, :string, :null => false
    end
    
    add_column :users, :openid_url, :string
  end

  def self.down    
    remove_column :users, :openid_url    
    drop_table :open_id_authentication_associations
    drop_table :open_id_authentication_nonces
  end
end