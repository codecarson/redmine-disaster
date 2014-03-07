#!/usr/bin/env ruby
require 'csv'
require 'active_record'
require 'mysql2'

# STEP 2
ActiveRecord::Base.establish_connection(
     adapter:  'mysql2',
     host:     'localhost',
     database: 'redmine',
     username: 'root',
     password: '???'
 )

class DumpedIssue < ActiveRecord::Base

  def self.concat(id)
    @issues = DumpedIssue.where(original: id).order(date: :asc)

    full_copy = @issues.map(&:content).join("\n\n\n--------------------------------------------\n\n\n")
    is_closed = @issues.map(&:status).include?('Closed')

    first_issue = @issues.first
    last_issue = @issues.last

    new_issue = NewIssue.new
    new_issue.name = first_issue.subject.gsub /\((New|Closed)\)\s/,''
    new_issue.status = last_issue.status
    new_issue.issue_id = first_issue.original
    new_issue.date_opened = first_issue.date
    new_issue.date_updated = last_issue.date
    new_issue.author = last_issue.author
    new_issue.assignee = last_issue.assignee
    new_issue.priority = last_issue.priority
    new_issue.content = full_copy
    new_issue.save

    # puts full_copy
    # puts "#{title}"
    # puts "CLOSED? #{is_closed}"
  end
end


# Issues Table is for Export
class NewIssue < ActiveRecord::Base
end


# DumpedIssue.concat(9551)

unique_issue_ids = DumpedIssue.distinct.pluck :original
unique_issue_ids.each { |id| DumpedIssue.concat(id) }
