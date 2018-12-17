class Dvla::Wizardflow::BaseController < ::ApplicationController
  include Dvla::Wizardflow::StepHelpers

  before_action :setup

  # expose some helpers to the views
  helper_method :step_path, :previous_step_path, :next_step_path, :previous_steps

  protected
  # retrieve the object in this controller's session key
  # return an instance of the passed klass
  def find_object(klass)
    controller_object = controller_session["object"]
    if controller_object.present?
      if controller_object.is_a? ApplicationModel
        return controller_object
      else
        return klass.new(controller_object)
      end
    end
    return nil
  end

  # save an object into this controller's session key
  def save_object(object, session_key = nil)
    # overwrite the current session object with the passed new one
    controller_session(session_key)["object"] = object
  end

  # delete the current object from this controller's session key
  def delete_object
    controller_session["object"] = nil
  end

  def clear_wizard_data
    session[controller_name] = nil
  end

  # TODO Currently Wizardflows must override this method to provide a lookup for
  # each step that posts to the save action. However, in future it would be good
  # to implement a Convention over configuration style setup where the base controller
  # uses convention to identify the model for a step and the Wizardflow controller
  # only needs to override the model_for_step method if it wishes to work in a
  # non standard manner.
  def model_for_step(step)
    raise_no_model_for_step(step)
  end

  # Default to no permitted attributes if wizard controller has not overriden
  def permitted_attributes_for_step(step)
    []
  end

  def whitelisted_params_for_step(step)
    raise_no_model_for_step(step) if model_for_step(step).nil?
    params.fetch(model_for_step(step).model_name.param_key, {}).permit(permitted_attributes_for_step(step))
  end

  private
  def setup
    setup_session()
  end

  def raise_no_model_for_step(step)
    raise "No model name lookup for step #{step} available in inheritance tree"
  end
end
