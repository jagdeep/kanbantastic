require 'active_model'
require 'httparty'

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

  class Task < Base
    attr_accessor :id, :title, :column_id, :updated_at, :moved_at, :task_type_id, :owner_id
    validates_presence_of :config, :id, :title, :column_id, :updated_at, :task_type_id

    def initialize(config, options = {})
      super(config)
      assign_attributes(options)
      @task_type_id = options[:task_type_id] || find_task_type_id(options[:task_type_name])
      valid?
    end

    def find_task_type_id(task_type_name)
      @task_type_ids ||= {}
      @task_type_ids[task_type_name] ||= if !task_type_name.blank?
        response = get("/projects/#{project_id}/task_types.json")
        task_type = response.select{|t| t[:name] == task_type_name}.first || Hash.new
        task_type[:id]
      end
    end

    def update(params={})
      params[:owner_id] ||= self.owner_id
      response = put("/tasks/#{id}.json", :body => {:task => params})
      if response[:id]
        assign_attributes(response)
        return valid?
      else
        self.class.invalid_response_error("Unable to update task.", response)
      end
    end

    def self.create(config, params={})
      # raise exception if title and task_type_name is not present
      unless params[:title] and params[:task_type_name]
        raise "Kanbanery task can't be created without title and task_type_name."
      end
      response = request(:post, config, "/projects/#{config.project_id}/tasks.json", :body => {:task => params})
      task = new(config, response)
      task.valid? ? task : invalid_response_error("Unable to create task.", response)
    end

    def column
      @columns ||= {}
      @columns[column_id] ||= Kanbantastic::Column.find(config, column_id)
    end

    def move_to_next_column
      update(:location => 'next_column')
    end

    def move_to_previous_column
      update(:location => 'prev_column')
    end

    def move_to_first_column
      result = true
      current_position = Kanbantastic::Column.find(config, column_id).position
      (current_position-1).times do
        result = false unless move_to_previous_column
      end
      return result
    end

    def move_to_second_column
      result = true
      current_position = Kanbantastic::Column.find(config, column_id).position
      if current_position > 2
        (current_position-2).times do
          result = false unless move_to_previous_column
        end
      elsif current_position < 2
        result = false unless move_to_next_column
      end
      return result
    end

    def move_to_last_column
      result = true
      last_position = Kanbantastic::Column.all(config).last.position
      (last_position - column.position).times do
        result = false unless move_to_next_column
      end
      return result
    end

    def archive
      if Kanbantastic::Task.archived?(config, id)
        return true
      else
        # raise an exception as only tasks which are in last column can be archived.
        unless column.last?
          raise "Kanbanery tasks can be archived only from the last column."
        end
        update(:location => "archive")
      end
    end

    def owner
      @owner ||= if owner_id
        response = get("/projects/#{project_id}/users.json")
        user = response.select{|r| r[:id] == owner_id}[0]
        Kanbantastic::User.new("#{user[:first_name]} #{user[:last_name]}", user[:email], user[:gravatar_url])
      end
    end

    def ==(task)
      id == task.id
    end

    def self.archived?(config, id)
      response = request(:get, config, "/projects/#{config.project_id}/archive/tasks.json")
      archived_task = response.select{|t| t[:id] == id}[0]
      archived_task ? true : false
    end

    def self.find(config, id)
      response = request(:get, config, "/tasks/#{id}.json")
      task = new(config, response)
      if task.valid?
        return task
      else
        return nil
      end
    end

    def self.all(config)
      collection = []
      response = request(:get, config, "/projects/#{config.project_id}/tasks.json")
      response.each do |data|
        task = self.new(config, data)
        collection << task if task.valid?
      end
      return collection
    end
  end

  class Column < Base
    attr_reader :id, :name, :position
    validates_presence_of :id, :name, :position

    def initialize(config, options={})
      super(config)
      @id = options[:id]
      @name = options[:name]
      @position = options[:position]
      self.valid?
    end

    def first?
      self.position == 1
    end

    def second?
      self.position == 2
    end

    def last?
      Kanbantastic::Column.all(config).last.id == id
    end

    def ==(column)
      id == column.id
    end

    def self.find(config, id)
      Kanbantastic::Column.all(config).select{|c| c.id == id }[0]
    end

    def self.all(config)
      collection = []
      response = request(:get, config, "/projects/#{config.project_id}/columns.json")
      response.each do |data|
        column = new(config, data)
        collection << column if column.valid?
      end
      return collection
    end
  end

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

  class User
    include ActiveModel::Validations
    attr_reader :name, :email, :avatar
    validates_presence_of :name, :email, :avatar

    def initialize(name, email, avatar)
      @name = name
      @email = email
      @avatar = avatar
      self.valid?
    end
  end
end