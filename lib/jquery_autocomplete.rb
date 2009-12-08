# JqueryAutocomplete

module ActionView
  module Helpers
    module  FormHelper
       def autocomplete_field(object_name, method, options = {})
         content_for :runview do
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

        options["type"] = "text"
        options_value = options['value']
        options["value"] ||= search_value_before_type_cast(object)
        options["value"] &&= html_escape(options["value"])
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
        options['value'] = options_value
        options["value"] ||= value_before_type_cast(object)
        options["value"] &&= html_escape(options["value"])


        add_default_name_and_id(options)
        result += tag("input", options)
      end

      def to_jquery_autocomplete_script(options = {})
        jcode =<<-EOC
        $("#ac_#{search_tag_id}").autocomplete("#{options[:url]}", {
           width: 260,
           selectFirst: false
        });
        $("#ac_#{search_tag_id}").result(function(event, data, formatted) {
           if (data)
             $(this).next().val(data[1]);
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

