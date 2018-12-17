module Dvla
  module Wizardflow
    # the class including this module needs to extend ActionController::Base
    # as it makes use of:
    # - session
    # - rails route helpers
    module StepHelpers
      def self.included(base)
        base.class_eval do
          @steps = []

          def self.set_steps(*steps)
            @steps = steps
          end

          def self.steps
            return @steps
          end
        end
      end

      def steps
        return self.class.steps
      end

      def current_step
        step = controller_session["current_step"]
        return step.to_sym if is_step(step)
        return nil
      end

      def previous_steps
        return controller_session["previous_steps"] || []
      end

      def previous_step
        steps = previous_steps
        if steps.present?
          return steps.last.to_sym if is_step(steps.last)
        end
        return nil
      end

      def next_step
        index = steps.index(current_step)
        if index.present? && index < steps.length
          return steps[index+1]
        end
        return nil
      end

      def first_step
        return steps.first
      end

      def last_step
        return steps.last
      end

      def is_first_step?
        return current_step == first_step
      end

      def is_last_step?
        return current_step == last_step
      end

      def step_path(step, params={})
        check_step(step)
        return url_for action: step.to_sym, **params
      end

      def previous_step_path
        return url_for action: previous_step
      end

      def next_step_path
        return url_for action: next_step
      end

      def first_step_path
        return url_for action: first_step
      end

      def last_step_path
        return url_for action: last_step
      end

      def redirect_to_previous_step
        redirect_to previous_step_path
      end

      def redirect_to_next_step
        redirect_to next_step_path
      end

      def redirect_to_first_step
        redirect_to first_step_path
      end

      def redirect_to_last_step
        redirect_to last_step_path
      end

      def redirect_to_step(step)
        redirect_to step_path(step)
      end

      def is_step(step)
        return step.present? && steps.include?(step.to_sym)
      end

      def check_step(step)
        raise "Unknown step: '#{step.to_s}'" if !is_step(step)
      end

      private
      def setup_session
        # setup session object if required
        if controller_session.blank?
          set_controller_session({
            "object": nil,
            "current_step": nil,
            "previous_steps": []
          })
        end

        this_step = action_name.to_sym
        if is_step(this_step)
          # if this step is different from the current_step, update the current / previous step session
          if current_step != this_step
            # if we haven't been to this page before, add it to the previous list
            if !previous_steps.include?(current_step)
              # previous step store
              prev_steps = previous_steps << current_step if current_step.present?
              controller_session["previous_steps"] = prev_steps
            end
            # current step store
            controller_session["current_step"] = this_step
          end
        elsif action_name.eql? 'save'
          # Check if the form params match the current step, if not and the action the
          # params relate to is in the previous step history then switch to the appropriate step.
          # This is to support the scenario that the back button has been used and a previous screen resubmitted
          # which would otherwise result in an error as no params would be whitelisted due to
          # the wrong key being used.
          if !params.has_key?(model_for_step(current_step).try(:model_name).try(:param_key))
            params_step = self.steps.find { |step| params.has_key?(model_for_step(step).try(:model_name).try(:param_key))   }
            controller_session["current_step"] = params_step.to_sym if (params_step.present? && previous_steps.include?(params_step.to_sym))
          end
        end

        # if we don't find a current object in the session on anything other than the first step. redirect user to the first step
        if controller_session["object"].blank? && !is_first_step?
          redirect_to_first_step()
        end
      end

      def controller_session(session_key = nil)
        if session_key.blank?
          return session[controller_name]
        else
          return session[session_key]
        end
      end

      def set_controller_session(data)
        session[controller_name] = data
      end

    end
  end
end
