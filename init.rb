# Include hook code here
%w{ models controllers helpers }.each do |dir|
  path = File.join(File.dirname(__FILE__), 'lib', 'app', dir)
  $LOAD_PATH << path
  ActiveSupport::Dependencies.load_paths << path
  ActiveSupport::Dependencies.load_once_paths.delete(path)
end

if defined?(ActionController)
  #require "lib/app/helpers/jquery_autocomplete_helper.rb"
  ActionController::Base.helper(JqueryAutocompleteHelper)
end