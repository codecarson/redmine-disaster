#!/usr/bin/env ruby
require 'csv'
require 'active_record'
require 'mysql2'

# STEP 3
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

class Enumeration < ActiveRecord::Base; end
class IssuePriority < Enumeration; end




class Issue < ActiveRecord::Base

  def self.create_from!(new_issue)
    issue = Issue.new
    issue.tracker_id = 3
    issue.project_id = 1  # 1= AUSNZ;  2=OFYQ ESC. CAN  ?????
    issue.status_id = IssueStatus.where(name: new_issue.status).first.try(:id) || 1
    issue.assigned_to_id = User.like(new_issue.assignee).first.try(:id)
    issue.priority_id = Enumeration.where(name: new_issue.priority).first.try(:id) || 2 # normal
    issue.created_on = new_issue.date_opened
    issue.updated_on = new_issue.date_updated
    issue.start_date = new_issue.date_opened
    issue.closed_on = new_issue.date_updated if new_issue.status == 'Closed'

    issue.author_id = User.like(new_issue.author).first.try(:id)

    if issue.author_id.nil?
      # puts "MISSING AUTHOR: #{new_issue.author}"
      issue.author_id = 2 # anonymous
    end

    issue.description = new_issue.content
    issue.subject = new_issue.name

    issue.lft = 1
    issue.rgt = 2
    issue.save

    # retain a reference to the record that was created so we can match up
    new_issue.update_attribute(:created_rec_id, issue.id)

    # update this after record creation, it is needed
    issue.update_attribute(:root_id, issue.id)
  end

  def self.import_all!
    NewIssue.all.each { |new_issue| self.create_from!(new_issue) }
  end
end



class User < ActiveRecord::Base

  scope :like, lambda {|q|
    q = q.to_s
    if q.blank?
      where({})
    else
      pattern = "%#{q}%"
      sql = %w(login firstname lastname mail).map {|column| "LOWER(#{table_name}.#{column}) LIKE LOWER(:p)"}.join(" OR ")
      params = {:p => pattern}
      if q =~ /^(.+)\s+(.+)$/
        a, b = "#{$1}%", "#{$2}%"
        sql << " OR (LOWER(#{table_name}.firstname) LIKE LOWER(:a) AND LOWER(#{table_name}.lastname) LIKE LOWER(:b))"
        sql << " OR (LOWER(#{table_name}.firstname) LIKE LOWER(:b) AND LOWER(#{table_name}.lastname) LIKE LOWER(:a))"
        params.merge!(:a => a, :b => b)
      end
      where(sql, params)
    end
  }
end



class IssueStatus < ActiveRecord::Base; end


# Issues Table is for Export
class NewIssue < ActiveRecord::Base
end

