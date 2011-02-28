module Kanbantastic

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
end
