# JqueryAutocomplete

module ActionView
  module Helpers
    module CaptureHelper
      def javascript_content_for(name, content = nil, &block)
        ivar = "#{name}_parts".to_sym
        jvar = "#{name}".to_sym
        content = capture(&block) if block_given?
        content_for(ivar,content)
        @_content_for[jvar] = %Q(<script type="text/javascript"><!-- \n#{@_content_for[ivar]} \n--></script>).html_safe
      end
    end

    module  FormHelper
       def autocomplete_field(object_name, method, options = {})
         options[:controller] = controller #ugly ugly hack, because InstanceTag needs the controller context to use url_for
         options[:widget_id] =  ActiveSupport::SecureRandom.hex(10)
         javascript_content_for :runview do
           InstanceTag.new(object_name, method, self, options.delete(:object)).to_jquery_autocomplete_script(options)
         end
         InstanceTag.new(object_name, method, self, options.delete(:object)).to_autocomplete_field_tag(options)
       end
    end


    class InstanceTag
      include Rails.application.routes.url_helpers
      def to_autocomplete_field_tag(options = {})
        options = options.stringify_keys
        options["size"] = options["maxlength"] || DEFAULT_FIELD_OPTIONS["size"] unless options.key?("size")
        options = DEFAULT_FIELD_OPTIONS.merge(options)
        options.delete("create_prompt")
        options.delete("create_value")
        options.delete("new_callback")
        options.delete("return")
        options.delete("resource")

        options["type"] = "text"
        options_value = options['value']
        if options.has_key? "display_value"
           options["value"] = html_escape(options["display_value"])
        else
          options["value"] ||= search_value_before_type_cast(object)
          options["value"] &&= html_escape(options["value"])
        end
        has_id = options.has_key?("id")
        options_id = options["id"]  #store for later
        options_name = options["name"] #store for later
        options.delete("url")

        add_search_name_and_id(options)
        result = tag("input", options)

        #reset for hidden field
        options["type"] = "hidden"
        options.delete("size")
        options.delete("id_prefix")
        if has_id
          options["id"] = options_id
        else
          options.delete("id")  # rails 3 now uses Hash#fetch, so if it wasn't defined before we have to get rid of the key
        end
        options["name"] = options_name
        options.delete("display_value")
        options['value'] = options_value
        options["value"] ||= value_before_type_cast(object)
        options["value"] &&= html_escape(options["value"])


        add_default_name_and_id(options)
        options['id'] += "_#{options['widget_id']}"
        result += tag("input", options)
      end

      def to_jquery_autocomplete_script(options = {})
        @controller = options[:controller]  #ugly ugly hack, because InstanceTag needs the controller context to use url_for
        options = options.stringify_keys
        options["allow_new"] = true if options["allow_new"].nil?
        options["return"] ||= "{label: item.#{options['resource']}.display_name,\nvalue: item.#{options['resource']}.id}"
        search_id=search_tag_id(options)
        hidden_tag_id = "#{tag_id}_#{options['widget_id']}"
        search_resource = options['resource']
        new_action = url_for(:only_path => true, :controller => search_resource.pluralize, :action =>'new')
        jcode =<<-EOC
        #{options["allow_new"] ? %|$('<div class="modal" id="new_#{options['widget_id']}_dialog"></div>').appendTo('body');| : ""}

        function handle_#{options['widget_id']}_json(response){
          $('#new_#{options['widget_id']}_dialog').dialog("close");
          $('##{search_id}')[0].value = response.#{search_resource}.display_name;
          $('##{hidden_tag_id}')[0].value = response.#{search_resource}.id;
        }

        $("##{search_id}").autocomplete({
          source: function(request, response) {
                  $.ajax({
                    url: "#{options["url"] || url_for(:only_path => true, :controller => search_resource.pluralize, :action => 'index')}",
                    dataType: "json",
                    data: {
                      q: request.term
                    },
                    success: function(data) {
                      #{autocomplete_response_mapping(options)}
                    }
                  })
                },
          minLength: 2,
          focus: function(event, ui) {
                  if(ui.item.value == "new") {
                    $('##{search_id}')[0].value = $('##{search_id}')[0].value
                  } else {
                    $('##{search_id}')[0].value = ui.item.label;
                  }
                  return false;
                },
          select: function(event, ui) {
                  if(ui.item.value == "new") {
                    $('#new_#{options['widget_id']}_dialog').load('#{new_action}','ac_widget=#{options['widget_id']}', function(response, status, xhr) {
                      $('#new_#{options['widget_id']}_dialog').dialog({modal: true, width: 500, height: 300, title: 'New #{search_resource.humanize}'});
                      $('#new_#{options['widget_id']}_dialog').scrollTop(0);
                    });
                  } else {
                    $('##{search_id}')[0].value = ui.item.label;
                    $('##{hidden_tag_id}')[0].value = ui.item.value;
                    $('##{hidden_tag_id}').change();  // fire the change() event in case someting is interested in it.
                  }
                  return false;
                }
        });
        EOC
        jcode.html_safe
      end

      private

      def add_search_name_and_id(options)
          options["name"] = search_tag_name(options)
          options["id"] = search_tag_id(options)
      end


      def search_tag_name(options)
        prefix = options["id_prefix"] || "ac_"
        prefix + "#{@object_name}[#{search_sanitized_method_name}]"
      end

      def search_tag_id(options)
        prefix = options["id_prefix"] || "ac_"
        prefix + "#{sanitized_object_name}_#{search_sanitized_method_name}_#{options['widget_id']}"
      end

      def search_sanitized_method_name
        @search_sanitized_method_name ||= @method_name.sub(/\?$/,"").sub(/_id$/,"")
      end

      def search_value_before_type_cast(object)
        search_value = self.class.value_before_type_cast(object, @method_name.sub(/_id$/,""))
        search_value ? search_value.display_name : ""
      end

      def autocomplete_response_mapping(options)
        if options['allow_new']
          %|response([{label: "New Item", value: "new"}].concat($.map(data, function(item) {
              return #{options["return"]}
          })))|
        else
          %|response($.map(data, function(item) {
              return #{options["return"]}
          }))|
        end
      end

      #ugly ugly hack, because InstanceTag needs the controller context to use url_for
      def controller
        @controller
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
