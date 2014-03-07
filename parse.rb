#!/usr/bin/env ruby
require 'csv'

# STEP1
# PARSES EMAIL CSV into Mysql-IMPORTABLE CSV

count = 0
CSV.open("out.csv", "wb") do |csv|
    CSV.foreach("sample.csv") do |row|
        count += 1
        puts "COUNT: #{count}"

        # puts "************"

        body = row[5]

        # puts body

        subject = body.match(/Subject:\n(.*)/)[1]
        from = body.match(/From:\n(.*)/)[1]
        date = body.match(/Date:\n(.*)/)[1]

        # Redmine properties
        redmine_attrs = Hash[*[:author, :status, :priority, :assignee].map do |attr|
            value = body.match(/.+?#{attr.capitalize}:(.*)$/)[1].strip
            puts "Parsing #{attr} => #{value}"
            [ attr, value ]
        end.flatten]

        # Extract everything after -- Reply above this line --
        content = body.match(/--- Reply above this line ---(.*)/m)[1].strip

        original_issue_num = content.match(/^Issue #(\d+) has been/)[1].strip
        is_new_issue = (content.match(/^Issue #(\d+) has been (\w+)/)[2].strip == 'reported')


    # puts redmine_attrs[:author]
    #   puts ">> DATE: #{date}"
    #   puts ">> AUTHOR: #{redmine_attrs[:author]}"
      puts ">> SUBJECT: #{subject}"
      puts "<< END"

    #   puts "Content: #{content}"

    #   puts redmine_attrs

    #   puts "************************"



        csv << [
            subject,
            date,
            is_new_issue,
            original_issue_num,
            redmine_attrs[:author],
            redmine_attrs[:status],
            redmine_attrs[:priority],
            redmine_attrs[:assignee],
            content
        ]
    end
end