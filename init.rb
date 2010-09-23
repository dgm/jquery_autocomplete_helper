# Include hook code here
require 'jquery_autocomplete'
if Formtastic.const_defined? :SemanticFormBuilder
  Formtastic::SemanticFormBuilder.send(:include, Formtastic::AutoComplete)
end