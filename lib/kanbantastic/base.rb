module Kanbantastic

  class Base
    include HTTParty
    include ActiveModel::Validations
    validates_presence_of :config

    attr_accessor :config

    def initialize(config)
      @config = config
      self.valid?
    end

    def get(url, options={})
      self.class.setup_headers(config.api_key)
      response = self.class.get(self.class.base_uri(config.workspace) + url, options).parsed_response
      self.class.symbolize_keys(response)
    end

    def post(url, options={})
      self.class.setup_headers(config.api_key)
      response = self.class.post(self.class.base_uri(config.workspace) + url, options).parsed_response
      self.class.symbolize_keys(response)
    end

    def put(url, options={})
      self.class.setup_headers(config.api_key)
      response = self.class.put(self.class.base_uri(config.workspace) + url, options).parsed_response
      self.class.symbolize_keys(response)
    end

    def project_id
      config.project_id
    end

    def assign_attributes(params={})
      params.each do |key, value|
        method_name = key.to_s+"="
        self.send(method_name, value) if self.respond_to?(method_name)
      end
      return self
    end

    def self.find_project_id(project_name, workspace_name, api_key)
      setup_headers(api_key)
      workspaces = get(base_uri(workspace_name) + "/user/workspaces.json").parsed_response
      if workspace_name
        workspace = workspaces.select{|w| w['name'] == workspace_name }.first
        project = workspace['projects'].select{|p| p['name'] == project_name }.first if workspace
      end
      return project['id'] if project
    end

    def self.request(method, config, url, options={})
      new(config).send(method.to_s, url, options)
    end

    def self.invalid_response_error(msg, response)
      begin
        text = response.map{|k,v| v.map{|e| "#{k} #{e}" }.join(', ')}.join(', ')
      rescue
        raise msg
      end
      raise "#{msg} #{text}"
    end

    private

    def self.base_uri workspace
      "https://#{workspace}.kanbanery.com/api/v1"
    end

    def self.setup_headers api_key
      headers['X-Kanbanery-ApiToken'] = api_key
    end

    def self.symbolize_keys(hsh)
      if hsh.class == Array
        hsh.map{|x| x.inject({}){|h,(k,v)| h[k.to_sym] = v; h}}
      else
        hsh.inject({}){|h,(k,v)| h[k.to_sym] = v; h}
      end
    end
  end
end
