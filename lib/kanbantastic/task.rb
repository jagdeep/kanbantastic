module Kanbantastic

  class Task < Base
    attr_accessor :id, :title, :column_id, :updated_at, :created_at, :moved_at, :task_type_id, :owner_id, :position
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
      begin
        response = put("/tasks/#{id}.json", :body => {:task => params})
      rescue Exception => e
        self.class.invalid_response_error("Unable to update task. #{e.message}", response)
      end
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
      column = Kanbantastic::Column.all(config).first
      update(:column_id => column.id, :position => nil)
    end

    def move_to_second_column
      column = Kanbantastic::Column.all(config)[1]
      update(:column_id => column.id, :position => nil)
    end

    def move_to_last_column
      column = Kanbantastic::Column.all(config).last
      update(:column_id => column.id, :position => nil)
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
      begin
        response = request(:get, config, "/tasks/#{id}.json")
      rescue
        return nil
      end
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
end
