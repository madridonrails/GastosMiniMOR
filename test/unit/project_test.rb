require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects
  
  NEW_PROJECT = {:name => 'Coche'}	# e.g. {:name => 'Test Project', :description => 'Dummy'}
  REQ_ATTR_NAMES = %w(name) # name of fields that must be present, e.g. %(name description)
  DUPLICATE_ATTR_NAMES = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)
  
  def setup
    # Retrieve fixtures via their name
    # @first = projects(:first)
  end

  def test_raw_validation
    project = Project.new
    if REQ_ATTR_NAMES.blank?
      assert project.valid?, "Project should be valid without initialisation parameters"
    else
      # If Project has validation, then use the following:
      assert !project.valid?, "Project should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert project.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

  def test_new
    project = Project.new(NEW_PROJECT)
    assert project.valid?, "Project should be valid\n" + project.errors.full_messages.to_s
    NEW_PROJECT.each do |attr_name|
      assert_equal NEW_PROJECT[attr_name], project.attributes[attr_name], "Project.@#{attr_name.to_s} incorrect"
    end
  end

  def test_validates_presence_of
    REQ_ATTR_NAMES.each do |attr_name|
      tmp_project = NEW_PROJECT.clone
      tmp_project.delete attr_name.to_sym
      project = Project.new(tmp_project)
      assert !project.valid?, "Project should be invalid, as @#{attr_name} is invalid"
      assert project.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end
end

