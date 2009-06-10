require 'yaml'
require 'erb'

namespace :gastosmini do

  desc "creates the schema of the database"
  task :create_schema => :environment do
    config = ActiveRecord::Base.configurations[RAILS_ENV]
    sql_for_encoding = config['encoding'] ? "character set #{config['encoding']}" : ''
    IO.popen("mysql -u root -p", 'w') do |pipe|
      pipe.write <<-SQL
        drop database if exists #{config['database']};
        create database #{config['database']} #{sql_for_encoding};
        grant all on #{config['database']}.* to '#{config['user']}'@'localhost' identified by '#{config['password']}';
      SQL
    end
  end
  
  desc "creates the schema and runs migrations"
  task :create_database => ['create_schema', 'db:migrate'] do
  end

  desc 'creates a dummy enterprise, owner to bootstrap development, tables will be cleared'
  task :create_dummy_models => :environment do
    Account.destroy_all
    dummy_account = Account.create(
      :name        => 'ASPgems, S.L.',
      :short_name  => 'aspgemstest',
      :blocked  => false
    )
    puts "created dummy account"
    
    u = dummy_account.users.create(
      :first_name            => 'Manuel',
      :last_name             => 'Castañeda',
      :email                 => 'admin@example.com',
      :email_confirmation    => 'admin@example.com',
      :password              => 'admin',
      :password_confirmation => 'admin',
      :activated_at          => Time.now
    )
    dummy_account.owner = u
    dummy_account.save!
    
    dummy_account.projects.create(
      :name => 'Gastosgem',
      :description  => 'Proyecto GastosGem'
    )
    puts "created #{dummy_account.projects.size} dummy projects for dummy account"
    
    transport = dummy_account.expense_types.create(
      :name => 'Transporte'
    )

    dummy_account.expense_types.create(
      :name => 'Taxi'
    )
    puts "created #{dummy_account.expense_types.size} dummy expense types for dummy account"
    
    expense = dummy_account.expenses.build(
      :date => Date.civil(2007, 3, 4),
      :amount => 12.0,
      :concept => 'Primer gasto'
    )
    expense.project = dummy_account.projects.first
    expense.expense_type = dummy_account.expense_types.first
    expense.save!

    expense = dummy_account.expenses.build(
      :date => Date.civil(2007, 3, 7),
      :amount => 25.0,
      :concept => 'Taxi al aeropuerto'
    )
    expense.project = dummy_account.projects[1]
    expense.expense_type = dummy_account.expense_types[2]
    expense.save!
    
    puts "created #{dummy_account.expenses.size} dummy expenses"
  end

  desc 'DESTROYs the current database, if any, and creates a new one with dummy models'
  task :init_for_development => [:create_database, :create_dummy_models] do
  end
end
