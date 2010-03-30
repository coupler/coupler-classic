module Coupler
  module Models
    module Jobify
      def self.included(base)
        base.one_to_many :jobs
        base.one_to_many(:running_jobs, {
          :class => "Coupler::Models::Job",
          :conditions => { :status => 'running' }, :read_only => true
        })
        base.one_to_many(:scheduled_jobs, {
          :class => "Coupler::Models::Job",
          :conditions => { :status => 'scheduled' }, :read_only => true
        })
      end
    end
  end
end
