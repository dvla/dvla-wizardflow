require 'test_helper'

module Dvla
  class Wizardflow::Test < ActiveSupport::TestCase
    include Rails.application.routes.url_helpers

    class StepsController < Dvla::Wizardflow::BaseController
      set_steps :step1, :step2, :step3
    end

    class SubflowStepsController < Dvla::Wizardflow::SubflowsController
      set_steps :subflow_step1, :subflow_step2
    end

    class MissingOverridesController < Dvla::Wizardflow::BaseController
      def call_model_for_step
        model_for_step(:step1)
      end

      def call_params_for_step
        permitted_attributes_for_step(:step1)
      end
    end

    test "truth" do
      assert_kind_of Module, Dvla::Wizardflow
    end

    test "controller" do
      assert_equal StepsController.new.steps.length, 3
      assert_equal SubflowStepsController.new.steps.length, 2

      # Check behaviour when controller does not override model_for_step
      err = assert_raises(RuntimeError) { MissingOverridesController.new.call_model_for_step }
      assert_match /No model name lookup for step/, err.message

      # Check behaviour when controller does not override permitted_attributes_for_step
      assert_equal MissingOverridesController.new.call_params_for_step, []

    end

    test "helpers" do
      # TODO need to mock out 'session' so we can unit test the helper methods in the libs
    end

    test "routes" do
      Dvla::Wizardflow::StepRouter.load

      assert_equal wizards_steps_step1_path, "/wizards/steps/step1"
    end
  end
end
