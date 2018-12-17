class Dvla::Wizardflow::SubflowsController < Dvla::Wizardflow::BaseController
  include Dvla::Wizardflow::SubflowStepHelpers

  helper_method :parent_next_step_path, :parent_previous_step_path

  protected
  def setup
    super()
    setup_subflow_session()
  end
end
