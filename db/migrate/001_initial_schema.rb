class InitialSchema < ActiveRecord::Migration
  def self.up    
    # Just a starting point, to be parametrized.
    
    create_table :sessions do |t|
      t.column :session_id, :string,   :references => nil
      t.column :data,       :text
      t.column :updated_at, :datetime
    end

    add_index :sessions, :session_id
    add_index :sessions, :updated_at
        
    create_table :accounts do |t|
      # owner
      t.column :owner_id,         :integer,  :references => nil # to avoid circularity with users skip the FK
      # web access
      t.column :short_name,       :string,   :null => false, :unique => true
      t.column :blocked,          :boolean,  :default => false, :null => false
      # data for our invoices to them
      t.column :name,             :string,   :null => false
      t.column :name_for_sorting, :string
      # logo
      t.column :logo,             :string
      # just created account
      t.column :direct_login,     :boolean,  :default => false
      # timestamps
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime        
    end
    
    create_table :expense_types do |t|
      t.column :account_id,       :integer, :null => false
      t.column :url_id,           :string,  :null => false, :references => nil
      t.column :name,             :string,  :null => false
      t.column :name_for_sorting, :string
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    add_index :expense_types, :url_id

    create_table :projects do |t|
      t.column :account_id,              :integer, :null => false
      t.column :url_id,                  :string,  :null => false, :references => nil
      t.column :name,                    :string
      t.column :name_for_sorting,        :string
      t.column :description,             :string
      t.column :description_for_sorting, :string
      t.column :notes,                   :text
      t.column :created_at,              :datetime
      t.column :updated_at,              :datetime
    end
    add_index :projects, :url_id
    
    create_table :users do |t|
      # account this user belongs to
      t.column :account_id,                :integer,   :null => false
      # personal data
      t.column :first_name,                :string
      t.column :first_name_for_sorting,    :string
      t.column :last_name,                 :string
      t.column :last_name_for_sorting,     :string
      # timestamps
      t.column :last_seen_at,              :timestamp
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      # authentication
      t.column :email,                     :string
      t.column :crypted_password,          :string,    :limit => 40
      t.column :salt,                      :string,    :limit => 40
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime
      t.column :activation_code,           :string,    :limit => 40
      t.column :activated_at,              :datetime
      # blocking flag
      t.column :is_blocked,                :boolean,   :default => false
    end
    
    create_table :expenses do |t|
      t.column :account_id,           :integer,  :null => false
      t.column :project_id,           :integer,  :null => false
      t.column :expense_type_id,      :integer,  :null => false
      t.column :date,                 :date
      t.column :amount,               :decimal,  :precision => 10, :scale => 2
      t.column :concept,              :string,   :null => false
      t.column :concept_for_sorting,  :string
      t.column :notes,                :text
      t.column :envelope,             :string
      t.column :envelope_for_sorting, :string
      t.column :created_at,           :datetime
      t.column :updated_at,           :datetime
    end    

    create_table :login_tokens do |t|
      t.column :account_id, :integer,   :null => true
      t.column :project_id, :integer,   :null => true
      t.column :type,       :string
      t.column :token,      :string,    :unique => true, :null => false
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
    add_index :login_tokens, :token

    create_table :chpass_tokens do |t|
      t.column :account_id, :integer,   :null => false
      t.column :token,      :string,    :unique => true, :null => false
      t.column :created_at, :timestamp
    end
    add_index :chpass_tokens, :token

  end

  def self.down
    remove_index :chpass_tokens, :token
    remove_index :login_tokens, :token
    remove_index :projects, :url_id
    remove_index :expense_types, :url_id
    drop_table :chpass_tokens
    drop_table :login_tokens
    drop_table :expenses
    drop_table :users
    drop_table :projects
    drop_table :expense_types
    drop_table :accounts
    drop_table :sessions
  end
end
