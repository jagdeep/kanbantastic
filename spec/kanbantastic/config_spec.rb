require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Kanbantastic::Config do
  use_vcr_cassette "cassette1"

  it "should have api_key, work_space and project_id" do
    config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
    config.api_key.should == API_KEY
    config.workspace.should == WORKSPACE
    config.project_id.should == PROJECT_ID
  end
end