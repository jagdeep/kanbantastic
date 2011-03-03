require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Kanbantastic::Task do

  describe "find_task_type_id" do
    use_vcr_cassette "cassette3"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.new(@config, :title => 'Test Task', :task_type_name => 'Work Package')
    end

    it "should return task type id if task type name is correct" do
      task_type_id = @task.find_task_type_id("Work Package")
      task_type_id.should_not be_nil
    end

    it "should return nil if task type name is incorrect" do
      task_type_id = @task.find_task_type_id("IncorrectName")
      task_type_id.should be_nil
    end

    it "should cache the value to avoid duplicate API calls" do
      task_type_id = @task.find_task_type_id("Work Package")
      @task.expects(:get).with("/projects/#{PROJECT_ID}/task_types.json").never

      task_type_id.should_not be_nil
      @task.find_task_type_id("Work Package").should equal(task_type_id)
    end
  end

  describe "create" do
    use_vcr_cassette "task/create"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
    end

    it "should create new task on kanbanery if title and task type name is present" do
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
      @task.id.should_not be_nil
      Kanbantastic::Task.find(@config, @task.id).should_not be_nil
    end
  end

  describe "update" do
    use_vcr_cassette "task/update"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should update task on kanbanery and return updated task" do
      old_updated_at = @task.updated_at
      @task.update(:title => "New title")
      @task.title.should == "New title"
      @task.updated_at.should > old_updated_at
      kanbanery_task = Kanbantastic::Task.find(@config, @task.id)
      kanbanery_task.should_not be_nil
      kanbanery_task.should == @task
      kanbanery_task.title.should == @task.title
      kanbanery_task.updated_at.should == @task.updated_at
    end
  end

  describe "column" do
    use_vcr_cassette "cassette6"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should return column which contains the task" do
      @task.column_id.should_not be_nil
      column = @task.column
      column.should_not be_nil
      column.class.should == Kanbantastic::Column
      column.id.should == @task.column_id
    end

    it "should cache the value to avoid duplicate API calls" do
      column = @task.column
      Kanbantastic::Column.expects(:find).never
      @task.column.should equal(column)
    end
  end

  describe "move_to_next_column" do
    use_vcr_cassette "task/move_to_next_column"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should move task in kanbanery to next column" do
      @task.column.should be_first
      @task.move_to_next_column.should be_true
      @task.column.should be_second
    end

    it "should raise an error if unable to move task" do
      @task.id = nil
      lambda{@task.move_to_next_column}.should raise_error(RuntimeError, "Unable to update task. 404 Not Found")
    end
  end

  describe "move_to_previous_column" do
    use_vcr_cassette "task/move_to_previous_column"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should move task in kanbanery to previous column" do
      @task.move_to_next_column
      @task.column.should be_second
      @task.move_to_previous_column.should be_true
      @task.column.should be_first
    end

    it "should raise an error if unable to move task" do
      @task.id = nil
      lambda{@task.move_to_previous_column}.should raise_error(RuntimeError, "Unable to update task. 404 Not Found")
    end
  end

  describe "move_to_first_column" do
    use_vcr_cassette "task/move_to_first_column"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should move task in kanbanery to first column" do
      @task.move_to_second_column
      @task.move_to_first_column.should be_true
      @task.column.should be_first
      @task.move_to_last_column
      @task.move_to_first_column.should be_true
      @task.column.should be_first
    end

    it "should raise an error if unable to move task" do
      @task.move_to_second_column
      @task.id = nil
      lambda{@task.move_to_first_column}.should raise_error(RuntimeError, "Unable to update task. 404 Not Found")
    end
  end

  describe "move_to_second_column" do
    use_vcr_cassette "task/move_to_second_column"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should move task in kanbanery to second column" do
      @task.move_to_first_column
      @task.move_to_second_column.should be_true
      @task.column.should be_second
      @task.move_to_last_column
      @task.move_to_second_column.should be_true
      @task.column.should be_second
    end

    it "should raise an error if unable to move task" do
      @task.id = nil
      lambda{@task.move_to_second_column}.should raise_error(RuntimeError, "Unable to update task. 404 Not Found")
    end
  end

  describe "move_to_last_column" do
    use_vcr_cassette "task/move_to_last_column"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should move task in kanbanery to last column" do
      @task.move_to_first_column
      @task.move_to_last_column.should be_true
      @task.column.should be_last
      @task.move_to_second_column
      @task.move_to_last_column.should be_true
      @task.column.should be_last
    end

    it "should raise an error if unable to move task" do
      @task.id = nil
      lambda{@task.move_to_last_column}.should raise_error(RuntimeError, "Unable to update task. 404 Not Found")
    end
  end

  describe "archive" do

    context "when task is in last column" do
      use_vcr_cassette "task/archive1"

      before do
        @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
        @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
        @task.should be_valid
      end

      it "should archive task in kanbanery and return true" do
        @task.column.should_not be_nil
        @task.move_to_last_column.should be_true
        @task.archive.should be_true
        Kanbantastic::Task.archived?(@config, @task.id).should be_true
      end
    end

    context "when task is not in last column" do
      use_vcr_cassette "task/archive2"

      before do
        @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
        @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
        @task.should be_valid
      end

      it "should return false" do
        @task.move_to_first_column.should be_true
        lambda{@task.archive}.should raise_error(RuntimeError, "Kanbanery tasks can be archived only from the last column.")
      end
    end
  end

  describe "update" do
    use_vcr_cassette "task/update"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should update the title" do
      @task.update(:title => "New title").should be_true
      @task.title.should == "New title"
    end
  end

  describe "owner" do
    use_vcr_cassette "task/owner"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
    end

    it "should return an owner object" do
      owner_id = Kanbantastic::Task.request(:get, @config, "/projects/#{PROJECT_ID}/users.json")[0][:id]
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package', :owner_id => owner_id)
      @task.should be_valid
      @task.owner_id.should == owner_id
      owner = @task.owner
      owner.class.should == Kanbantastic::User
      owner.email.should_not be_nil
      owner.avatar.should_not be_nil
    end

    it "should return nil if owner_id is nil" do
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package', :owner_id => nil)
      @task.should be_valid
      @task.owner_id = nil
      @task.owner_id.should be_nil
      @task.owner.should be_nil
    end

    it "should cache the value to avoid duplicate API calls" do
      owner_id = Kanbantastic::Task.request(:get, @config, "/projects/#{PROJECT_ID}/users.json")[0][:id]
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package', :owner_id => owner_id)
      owner = @task.owner
      owner.should_not be_nil
      Kanbantastic::Task.expects(:get).with("/projects/#{PROJECT_ID}/users.json").never
      @task.owner.should equal(owner)
    end
  end

  describe "archived?" do
    context "when task is not archived" do
      use_vcr_cassette "task/archived1"

      before do
        @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
        @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
        @task.should be_valid
      end

      it "should return false" do
        @task.column.should be_first
        Kanbantastic::Task.archived?(@config, @task.id).should be_false
      end
    end

    context "when task is archived" do
      use_vcr_cassette "task/archived12"

      before do
        @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
        @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
        @task.should be_valid
      end

      it "should return true" do
        @task.move_to_last_column.should be_true
        @task.column.should be_last
        @task.archive.should be_true
        @task.column.should be_nil
        Kanbantastic::Task.archived?(@config, @task.id).should be_true
      end
    end
  end

  describe "find" do
    use_vcr_cassette "task/find"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should return nil if task not found" do
      Kanbantastic::Task.find(@config, 'fakeid').should be_nil
    end

    it "should return task if found" do
      result = Kanbantastic::Task.find(@config, @task.id)
      result.should_not be_nil
      result.class.should == Kanbantastic::Task
      result.should == @task
      result.title.should_not be_nil
      result.column_id.should_not be_nil
      result.updated_at.should_not be_nil
      result.task_type_id.should_not be_nil
    end
  end

  describe "all" do
    use_vcr_cassette "task/all", :record => :new_episodes

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @task = Kanbantastic::Task.create(@config, :title => 'Test Task', :task_type_name => 'Work Package')
      @task.should be_valid
    end

    it "should return an array of tasks" do
      tasks = Kanbantastic::Task.all(@config)
      tasks.class.should == Array
      tasks.first.class.should == Kanbantastic::Task
      tasks.select{|t| t.id == @task.id}.first.should_not be_nil
    end
  end
end
