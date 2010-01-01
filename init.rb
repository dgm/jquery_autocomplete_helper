# Include hook code here
require 'jquery_autocomplete'
if Formtastic.constants.include?("SemanticFormBuilder")
  Formtastic::SemanticFormBuilder.send(:include, Formtastic::AutoComplete)
end