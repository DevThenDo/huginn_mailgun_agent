require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::MailgunAgent do
  before(:each) do
    @valid_options = Agents::MailgunAgent.new.default_options
    @checker = Agents::MailgunAgent.new(:name => "MailgunAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
