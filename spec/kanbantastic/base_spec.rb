require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Kanbantastic::Base do

  describe "find_project_id" do
    use_vcr_cassette "workspaces_with_projects"

    it "should project id for valid project name" do
      Kanbantastic::Base.find_project_id("Envision Integration", WORKSPACE, API_KEY).should == PROJECT_ID
    end

    it "should return nil for invalid project name" do
      Kanbantastic::Base.find_project_id("Invalid Project", WORKSPACE, API_KEY).should be_nil
    end
  end

  describe "project_id" do
    it "should return project id from config" do
      config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      obj = Kanbantastic::Base.new(config)
      obj.should be_valid
      obj.project_id.should == config.project_id
    end
  end

  describe "assign_attributes" do
    it "should asign attributes from a hash" do
      config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      obj = Kanbantastic::Base.new(nil)
      obj.should_not be_valid
      obj.config.should be_nil
      obj.assign_attributes({:config => config})
      obj.config.should_not be_nil
      obj.config.should == config
    end
  end

  describe "invalid_response_error" do
    context "when response is a hash of errors" do
      it "should raise an error with all the error messages combined with the custom message" do
        response = {:field => ["test error"]}
        lambda{Kanbantastic::Base.invalid_response_error("error", response)}.should raise_error(RuntimeError, "error field test error")
      end
    end

    context "when response is not a hash of errors" do
      it "should raise an error with only the custom message" do
        response = "test error"
        lambda{Kanbantastic::Base.invalid_response_error("error", response)}.should raise_error(RuntimeError, "error")
      end
    end
  end

  describe "post" do
    use_vcr_cassette "base/post"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @obj = Kanbantastic::Base.new(@config)
      @obj.should be_valid
    end

    it "should raise an error when url is not a string" do
      lambda{@obj.post(nil)}.should raise_error RuntimeError, "url must be a String."
    end

    it "should raise an error when options is not a hash" do
      lambda{@obj.post('test', 'wrong options')}.should raise_error RuntimeError, "options must be a Hash."
    end

    it "should raise an error when response code is not 201" do
      lambda{@obj.post('test')}.should raise_error RuntimeError, "404 Not Found"
    end

    it "should return parsed response when response code is 201" do
      response = @obj.post("/projects/#{@config.project_id}/tasks.json", :body => {:task => {:title => "Testing", :task_type_name => "Work Package"}})
      response[:title].should == "Testing"
      response[:type].should == "Task"
    end
  end

  describe "get" do
    use_vcr_cassette "base/get", :record => :new_episodes

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @obj = Kanbantastic::Base.new(@config)
      @obj.should be_valid
    end

    it "should raise an error when url is not a string" do
      lambda{@obj.get(nil)}.should raise_error RuntimeError, "url must be a String."
    end

    it "should raise an error when options is not a hash" do
      lambda{@obj.get('test', 'wrong options')}.should raise_error RuntimeError, "options must be a Hash."
    end

    it "should raise an error when response code is not 200" do
      lambda{@obj.get('test')}.should raise_error RuntimeError, "404 Not Found"
    end

    it "should return parsed response when response code is 200" do
      response = @obj.get("/user/workspaces.json")
      response.class.should == Array
      response.first[:type].should == "Workspace"
    end
  end

  describe "put" do
    use_vcr_cassette "base/put"

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @obj = Kanbantastic::Base.new(@config)
      @obj.should be_valid
    end

    it "should raise an error when url is not a string" do
      lambda{@obj.put(nil)}.should raise_error RuntimeError, "url must be a String."
    end

    it "should raise an error when options is not a hash" do
      lambda{@obj.put('test', 'wrong options')}.should raise_error RuntimeError, "options must be a Hash."
    end

    it "should raise an error when response code is not 200" do
      lambda{@obj.put('/tasks/2.json', :body => {:task => {}})}.should raise_error RuntimeError, "404 Not Found"
    end

    it "should return parsed response when response code is 200" do
      task = @obj.post("/projects/#{@config.project_id}/tasks.json", :body => {:task => {:title => "Testing", :task_type_name => "Work Package"}})
      response = @obj.put("/tasks/#{task[:id]}.json", :body => {:task => {:title => "Testing123"}})
      response.class.should == Hash
      response[:title].should == "Testing123"
      response[:id].should == task[:id]
    end
  end

  describe "rectify_time" do

    before do
      @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
      @obj = Kanbantastic::Base.new(@config)
      @obj.should be_valid
    end

    it "should fix updated_at, created_at and moved_at when time is set in future" do
      future_time = Time.now.utc + 9000
      response = {:created_at => future_time, :updated_at => future_time, :moved_at => future_time}
      response = Kanbantastic::Base.send("rectify_time", response, future_time)
      response[:created_at].should == (future_time - 9000)
      response[:updated_at].should == (future_time - 9000)
      response[:moved_at].should == (future_time - 9000)
    end

    it "should fix updated_at, created_at and moved_at when time is set in past" do
      past_time = Time.now.utc - 9000
      response = {:created_at => past_time, :updated_at => past_time, :moved_at => past_time}
      response = Kanbantastic::Base.send("rectify_time", response, past_time)
      response[:created_at].should == (past_time + 9000)
      response[:updated_at].should == (past_time + 9000)
      response[:moved_at].should == (past_time + 9000)
    end
  end
end
