# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.3' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Include your application configuration below

# The idiomatic way to do this is to write a plugin, but I don't have time to do that.     
class ActiveRecord::Base
  # This class method generates methods like this one:
  #
  # def first_name=(fname)
  #    write_attribute(:first_name, fname)
  #    write_attribute(:first_name_for_sorting, GastosminiUtils.normalize_for_sorting(fname))
  #  end
  def self.add_for_sorting_to(*fields)
    fields.each do |f|
      class_eval <<-EOS
        def #{f}=(v)
          write_attribute(:#{f}, v)
          write_attribute(:#{f}_for_sorting, GastosminiUtils.normalize_for_sorting(v))
        end
      EOS
    end
  end
end

class Logger
  def format_message(severity, timestamp, progname, msg)
    "[#{timestamp.strftime('%Y/%m/%d %H:%M:%S')}] (#{$$}) [#{severity}]: #{msg}\n"
  end
end

class ActiveRecord::ConnectionAdapters::Column
  class << self
    alias :original_value_to_decimal :value_to_decimal
    def value_to_decimal(v)
      if v.is_a?(String)
        # We try first our parsing because the original method always
        # returns a BigDecimal and there's no way AFAIK to know whether
        # the constructor ignored part of the string. For example "1,3"
        # gives 1, whereas we want 1.3.
        GastosminiUtils.parse_decimal(v)
      else
        original_value_to_decimal(v)
      end
    end
    
    # This method is called both when dates are set in the model, and
    # when dates are loaded from the database. So we let the original
    # parser do its job, and give a chance to ours if it fails.
    alias :original_string_to_date :string_to_date
    def string_to_date(v)
      if v.is_a?(String) && v =~ %r{^\d+/\d+/\d+$}
        GastosminiUtils.parse_date(v)
      else
        original_string_to_date(v)
      end
    end
  end
end

class String
  # It increases the leftmost integer found in the String. For example we get
  # "F10" as "F9".isucc, whereas standard "F9".succ gives "G0".
  def isucc
    self.dup.isucc!
  end
  
  def isucc!
    sub!(/\d+/) {|i| i.succ}
  end
end

class NilClass
  # When we negate a discount or IRPF we don't want to depend on whether it
  # is nil or not, we define minus nil to be nil.
  def -@
    nil
  end
end

# This hack prevents form helpers from puttin a fieldWithErrors DIV around
# field with errors. That introduced breaks if the field happened to have
# something to its right as a help icon.
ActionView::Base.field_error_proc = lambda {|html_tag, instance| html_tag}

local_config_rb = File.join(RAILS_ROOT, 'config', 'local_config.rb')
if not File.exists?(local_config_rb)
  puts "Missing config/local_config.rb, aborting"
  exit 1
end
require local_config_rb

gastosmini_yml = File.join(RAILS_ROOT, 'config', 'gastosmini.yml')
if not File.exists?(gastosmini_yml)
  puts "Missing config/gastosmini.yml, aborting"
  exit 1
end
CONFIG = YAML::load(File.open(gastosmini_yml))

mailer_rb = File.join(RAILS_ROOT, 'config', 'mailer.rb')
if not File.exists?(mailer_rb)
  puts "Missing config/mailer.rb, aborting"
  exit 1
end
require mailer_rb

# FIX: DoS vulnerabilities in REXML - http://feeds.feedburner.com/~r/RidingRails/~3/372559660/dos-vulnerabilities-in-rexml
require 'rexml-expansion-fix'

# Let the plugin replace send_file with its own in production mode.
XSendFile::Plugin.replace_send_file! if RAILS_ENV == 'production'
