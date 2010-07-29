module Coupler
  module Extensions
    class ProjectNotFound < Exception; end
    class ResourceNotFound < Exception; end
    class FieldNotFound < Exception; end
    class TransformationNotFound < Exception; end
    class ScenarioNotFound < Exception; end
    class MatcherNotFound < Exception; end
    class ResultNotFound < Exception; end
    class ImportNotFound < Exception; end

    module Exceptions
      def self.registered(app)
        app.error ProjectNotFound do
          flash[:notice] = "The project you were looking for doesn't exist."
          flash[:notice_class] = 'error'
          redirect '/projects'
        end

        app.error ResourceNotFound do
          flash[:notice] = "The resource you were looking for doesn't exist."
          flash[:notice_class] = 'error'
          redirect "/projects/#{@project.id}/resources"
        end

        app.error TransformationNotFound do
          flash[:notice] = "The transformation you were looking for doesn't exist."
          flash[:notice_class] = 'error'
          redirect "/projects/#{@project.id}/resources/#{@resource.id}/transformations"
        end

        app.error ScenarioNotFound do
          flash[:notice] = "The scenario you were looking for doesn't exist."
          flash[:notice_class] = 'error'
          redirect "/projects/#{@project.id}/scenarios"
        end

        app.error MatcherNotFound do
          flash[:notice] = "The matcher you were looking for doesn't exist."
          flash[:notice_class] = 'error'
          redirect "/projects/#{@project.id}/scenarios/#{@scenario.id}"
        end

        app.error ResultNotFound do
          flash[:notice] = "The result you were looking for doesn't exist."
          flash[:notice_class] = 'error'
          redirect "/projects/#{@project.id}/scenarios/#{@scenario.id}/results"
        end

        app.error ImportNotFound do
          flash[:notice] = "The import you were looking for doesn't exist."
          flash[:notice_class] = 'error'
          redirect "/projects/#{@project.id}"
        end
      end
    end
  end
end
