module JqueryAutocompleteHelper
    def auto_complete_field(parent, child)
      out = %Q(<input type="text" id="ac_#{parent.to_s.underscore}_#{child.to_s.underscore}" class="autocomplete_search" value="#{(obj = instance_variable_get(:"@#{parent.to_s}").send(child.to_s)) ? obj.display_name : ""}">)
      out +=  hidden_field parent, child.to_s + "_id"
       
      jcode =<<-EOC
      $("#ac_#{parent.to_s.underscore}_#{child.to_s.underscore}").autocomplete("#{polymorphic_path(child.to_s.pluralize.to_sym)}", {
         width: 260,
         selectFirst: false
      });
      $(".autocomplete_search").result(function(event, data, formatted) {
         if (data)
           $(this).next().val(data[1]);
      });
      EOC
      content_for :runview do
        jcode
      end
      out
    end
end 