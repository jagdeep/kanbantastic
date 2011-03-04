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
      check_parameter_format(:url => [url, String], :options => [options, Hash])

      self.class.setup_headers(config.api_key)
      response = self.class.get(self.class.base_uri(config.workspace) + url, options)
      if response.code == 200
        self.class.symbolize_keys(response.parsed_response)
      else
        raise response.headers['status']
      end
    end

    def post(url, options={})
      check_parameter_format(:url => [url, String], :options => [options, Hash])

      self.class.setup_headers(config.api_key)
      response = self.class.post(self.class.base_uri(config.workspace) + url, options)
      if response.code == 201
        self.class.symbolize_keys(response.parsed_response)
      else
        raise response.headers['status']
      end
    end

    def put(url, options={})
      check_parameter_format(:url => [url, String], :options => [options, Hash])

      self.class.setup_headers(config.api_key)
      response = self.class.put(self.class.base_uri(config.workspace) + url, options)
      if response.code == 200
        self.class.symbolize_keys(response.parsed_response)
      else
        raise response.headers['status']
      end
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

    def check_parameter_format options={}
      raise "options must be a Hash" unless options.instance_of?(Hash)
      options.each do |key, value|
        raise "options Hash must have each key as a Symbol or a String" unless key.instance_of?(Symbol) or key.instance_of?(String)
        if value.class != Array or value.length != 2 or value[1].class != Class
          raise "each value of options Hash must be an Array of a parameter and its expected class."
        end
        raise "#{key} must be a #{value[1]}." unless value[0].instance_of? value[1]
      end
    end

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
