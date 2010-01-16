# JqueryAutocomplete

module ActionView
  module Helpers
    module CaptureHelper
      def javascript_content_for(name, content = nil, &block)
        ivar = "@content_for_#{name}_parts"
        jvar = "@content_for_#{name}"
        content = capture(&block) if block_given?
        instance_variable_set(ivar, "#{instance_variable_get(ivar)}#{content}")
        if  "".respond_to? :html_safe!
          instance_variable_set(jvar, %Q(<script type="text/javascript">#{instance_variable_get(ivar)}</script>)).html_safe!
        else
          instance_variable_set(jvar, %Q(<script type="text/javascript">#{instance_variable_get(ivar)}</script>))
        end
        nil
      end
    end

    module  FormHelper
       def autocomplete_field(object_name, method, options = {})
         javascript_content_for :runview do
           InstanceTag.new(object_name, method, self, options.delete(:object)).to_jquery_autocomplete_script(options)
         end
          InstanceTag.new(object_name, method, self, options.delete(:object)).to_autocomplete_field_tag(options)
       end
    end


    class InstanceTag
      def to_autocomplete_field_tag(options = {})
        options = options.stringify_keys
        options["size"] = options["maxlength"] || DEFAULT_FIELD_OPTIONS["size"] unless options.key?("size")
        options = DEFAULT_FIELD_OPTIONS.merge(options)
        options.delete("create_prompt")
        options.delete("create_value")

        options["type"] = "text"
        options_value = options['value']
        if options.has_key? "display_value"
           options["value"] = html_escape(options["display_value"])
        else
          options["value"] ||= search_value_before_type_cast(object)
          options["value"] &&= html_escape(options["value"])
        end
        options_id = options["id"]  #store for later
        options_name = options["name"] #store for later

        add_search_name_and_id(options)
        result = tag("input", options)

        #reset for hidden field
        options["type"] = "hidden"
        options.delete("size")
        options.delete("url")
        options["id"] = options_id
        options["name"] = options_name
        options.delete("display_value")
        options['value'] = options_value
        options["value"] ||= value_before_type_cast(object)
        options["value"] &&= html_escape(options["value"])


        add_default_name_and_id(options)
        result += tag("input", options)
      end

      def to_jquery_autocomplete_script(options = {})
        options[:create_prompt] ||= "Create new entry?"
        options[:create_value] ||= "AUTOCOMPLETE_NEW"
        jcode =<<-EOC
        $("#ac_#{search_tag_id}").autocomplete("#{options[:url]}", {
           width: 260,
           selectFirst: false
        });
        $("#ac_#{search_tag_id}").result(function(event, data, formatted) {
           if (data) {
             $(this).next().val(data[1]);
           } else {
             if ($(this).val() && confirm("#{options[:create_prompt]}")) {
               $(this).next().val("#{options[:create_value]}");
             } else {
               $(this).next().val("");
             }
           }
        });
        $("#ac_#{search_tag_id}").blur(function() {
           if ($(".ac_results").size() == 0 || $(".ac_results").css("display") == "none") {
             $("#ac_organization_person_organization").search();
           }
        });
        EOC
      end

      private

      def add_search_name_and_id(options)
          options["name"] = "ac_" + search_tag_name
          options["id"] = "ac_" + search_tag_id
      end


      def search_tag_name
        "#{@object_name}[#{search_sanitized_method_name}]"
      end

      def search_tag_id
        "#{sanitized_object_name}_#{search_sanitized_method_name}"
      end

      def search_sanitized_method_name
        @search_sanitized_method_name ||= @method_name.sub(/\?$/,"").sub(/_id$/,"")
      end

      def search_value_before_type_cast(object)
        search_value = self.class.value_before_type_cast(object, @method_name.sub(/_id$/,""))
        search_value ? search_value.display_name : ""
      end
    end

    class FormBuilder
      def autocomplete_field(method, options = {})
        @template.autocomplete_field(@object_name, method, objectify_options(options))
      end
    end
  end
end

module Formtastic
  module AutoComplete
    protected
    def autocomplete_input(method, options = {})
      self.label(method, options_for_label(options)) <<
      self.autocomplete_field(method, options)
    end
  end
end
