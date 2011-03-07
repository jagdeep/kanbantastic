require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Kanbantastic::Column do
  use_vcr_cassette "cassette2", :erb => true

  before do
    @config = Kanbantastic::Config.new(API_KEY, WORKSPACE, PROJECT_ID)
  end

  describe "all" do
    it "should return an array of columns" do
      columns = Kanbantastic::Column.all(@config)
      columns.class.should == Array
      columns.should_not be_blank
      columns.first.name.should_not be_nil
      columns.first.position.should_not be_nil
      columns.first.id.should_not be_nil
    end
  end

  describe "find" do
    it "should return the column" do
      column1 = Kanbantastic::Column.all(@config)[0]
      column1.should_not be_nil
      column2 = Kanbantastic::Column.find(@config, column1.id)
      column2.should == column1
    end
  end

  describe "first?" do
    before do
      @columns = Kanbantastic::Column.all(@config)
    end

    it "should return true if its first column" do
      column = @columns.select{|c| c.position == 1}[0]
      column.should_not be_nil
      column.should be_first
    end

    it "should return false if its not the first column" do
      column = @columns.select{|c| c.position == 2}[0]
      column.should_not be_nil
      column.should_not be_first
    end
  end

  describe "second?" do
    before do
      @columns = Kanbantastic::Column.all(@config)
    end

    it "should return true if its second column" do
      column = @columns.select{|c| c.position == 2}[0]
      column.should_not be_nil
      column.should be_second
    end

    it "should return false if its not the second column" do
      column = @columns.select{|c| c.position == 1}[0]
      column.should_not be_nil
      column.should_not be_second
    end
  end

  describe "last?" do
    before do
      @columns = Kanbantastic::Column.all(@config)
    end

    it "should return true if its last column" do
      column = @columns.last
      column.position.should == @columns.length
      column.should be_last
    end

    it "should return false if its not the last column" do
      column = @columns.select{|c| c.position == 1}[0]
      column.should_not be_nil
      column.should_not be_last
    end
  end
end