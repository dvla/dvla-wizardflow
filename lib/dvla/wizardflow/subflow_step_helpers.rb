module Dvla
  module Wizardflow
    # the class including this module needs to extend Wizards::BaseController
    # as it makes use of:
    # - session
    # - rails route helpers
    module SubflowStepHelpers
      def setup_subflow_session
        # gather and store information about the parent flow
        parent_next_step_path = params["parent_next_step_path"]
        parent_previous_step_path = params["parent_previous_step_path"]

        if parent_next_step_path.present? && parent_previous_step_path.present?
          path_data = Rails.application.routes.recognize_path(parent_next_step_path)
          if path_data.present?
            # store parent_controller from the parent_next_step_path
            # TODO: These values should probably be passed explicitly rather than getting it from a path
            #       since we'll always be navigating back to the parent flow before moving elsewhere
            controller_session["parent_controller"] = path_data[:controller].gsub("wizards/", "")
            controller_session["parent_next_step"] = path_data[:action]
          end

          path_data = Rails.application.routes.recognize_path(parent_previous_step_path)
          if path_data.present?
            controller_session["parent_previous_step"] = path_data[:action]
          end

          controller_session["parent_attribute"] = params["parent_attribute"]
          controller_session["wizard_title"] = params["wizard_title"]

          # user has come into the subflow via the parent's controller action
          # copy the object from the parent object into the current object if one exists
          # this ensures that details from one subflow doesn't appear in another subflow when jumping between urls
          save_object(get_parent_object(controller_session["parent_attribute"]))
        end
        # TODO: Think of a way to go back to the start of the parent flow when we lose the session and try to reload a subflow screen
        # this flow must be called from another flow and we must have all of the required information
        raise ActionController::RoutingError.new('Not Found') if controller_session["parent_controller"].blank?
        raise "Session expired" if session[controller_session["parent_controller"]].blank?
      end

      def get_parent_object(attribute = nil)
        parent_controller = controller_session["parent_controller"]
        parent_data = session[parent_controller]["object"]

        if parent_data.is_a? ApplicationModel
          parent_object = parent_data
        else
          parent_object = "Wizard::#{parent_controller.singularize.titlecase}::#{parent_controller.singularize.titlecase}".constantize.new(parent_data)
        end

        if parent_object.present?
          if attribute.present?
            if parent_object.respond_to? "#{attribute}="
              return parent_object.send("#{attribute}")
            else
              raise "Invalid attribute: #{attribute} on #{parent_object.class.name}"
            end
          else
            return parent_object
          end
        end
      end

      def save_parent_object(object)
        parent_attribute = controller_session["parent_attribute"]
        if parent_attribute.present?
          parent_object = get_parent_object()
          if parent_object.present?
            if parent_object.respond_to? "#{parent_attribute}="
              parent_object.send("#{parent_attribute}=", object)
              save_object(parent_object, controller_session["parent_controller"])
            end
          end
        end
      end

      def parent_previous_step_path
        return url_for controller: controller_session["parent_controller"], action: controller_session["parent_previous_step"]
      end

      # get the path of the next step from the parent - this is the one passed through to this subflow
      def parent_next_step_path
        return url_for controller: controller_session["parent_controller"], action: controller_session["parent_next_step"]
      end
    end
  end
end
