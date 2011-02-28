module Kanbantastic

  class Config
    include ActiveModel::Validations
    attr_reader :api_key, :workspace, :project_id
    validates_presence_of :api_key, :workspace, :project_id

    def initialize(api_key, workspace, project_id)
      @api_key = api_key
      @workspace = workspace
      @project_id = project_id
      self.valid?
    end
  end
end