module ActiveAdmin
  module Views
    class ShowPage < BasePage

      def config
        active_admin_config.page_configs[:show] || ::ActiveAdmin::PageConfig.new
      end

      def title
        case config[:title]
        when Symbol, Proc
          call_method_or_proc_on(resource, config[:title])
        when String
          config[:title]
        else
          default_title
        end
      end

      def main_content
        html = if config.block
          # Eval the show config from the controller
          instance_eval &config.block
        else
          default_main_content
        end
        html + (comments if active_admin_config.admin_notes?)
      end
      
      def comments
        render view_factory.admin_notes, resource
      end

      protected

      def default_title
        "#{active_admin_config.resource_name} ##{resource.id}"
      end

      def default_empty
        content_tag :span, "Empty", :class => "empty"
      end

      def default_main_content
        table_options = {
          :border => 0, 
          :cellpadding => 0, 
          :cellspacing => 0,
          :id => "#{resource_class.name.underscore}_attributes",
          :class => "resource_attributes"
        }        
        content_tag :table, table_options do
          show_view_columns.collect do |attr|
            content_tag :tr do
              content_tag(:th, attr.to_s.titlecase) + content_tag(:td, default_content_for(resource, attr))
            end
          end.join.html_safe
        end        
      end

      def default_content_for(resource, attr)
        if attr.to_s =~ /^([\w]+)_id$/ && resource.respond_to?($1.to_sym)
          default_content_for(resource, $1)
        else
          value = pretty_format(resource.send(attr.to_sym))
          value == "" ? default_empty : value
        end
      end

    end
  end
end
