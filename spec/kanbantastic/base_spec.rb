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
end