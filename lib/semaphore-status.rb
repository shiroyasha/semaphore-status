# -*- coding: utf-8 -*-

require "rubygems"
require "bundler"

Bundler.setup

require_relative "semaphore-status/version"
require "open-uri"
require "json"
require "time"
require "colorize"

class SemaphoreClient

  API_HOST = "https://semaphoreci.com"
  API_URL  = "/api/v1/projects"

  def initialize(token)
    url = "#{API_HOST}#{API_URL}?auth_token=#{token}"

    response = open(url).read
    @json_response = JSON.parse(response)
  end

  def tree(query = nil)
    if query
      projects = search(query)
      if projects.empty?
        puts 'This git repository is not on Semaphore.'
        self.tree
        return
      end
    else
      projects = @json_response
    end

    if @json_response.size == projects.size
      puts 'Your projects on Semaphore:'
    else
      puts "Displaying #{projects.size} of #{@json_response.size} projects:"
    end

    projects.each_with_index do |project, index|
      if index+1 == projects.size
        print_project(project,'last')
      else
        print_project(project)
      end
    end
  end

  private

  def search(query)
    @json_response.select { |project| project['name'] == query }
  end

  def print_project(project, order = 'first')
    if order == 'last'
      puts "└── #{project["name"].yellow}"
      print_branches(project['branches'],'last')
    else
      puts "├── #{project["name"].yellow}"
      print_branches(project['branches'])
    end
  end

  def print_branches(branches, order = 'first')
    branches.each_with_index do |branch, index|
      print '|' if order != 'last'
      print '   '
      if index == branches.length - 1
        print_branch(branch, 'last')
      else
        print_branch(branch)
      end
      puts ""
    end
  end

  def print_branch(branch, order = 'first')
    if order == 'last'
      print "└── "
    else
      print "├── "
    end
    print branch_info(branch)
  end

  def branch_info(branch)
    finished_at   = branch["finished_at"]
    branch_name   = branch["branch_name"]
    branch_result = branch["result"]
    build_number  = branch["build_number"]
    build_time    = calculate_time(finished_at)

    info = "#{branch_name} :: #{branch_result} (#{build_number})"

    colorized_info = case branch_result
                     when "passed" then info.green
                     when "failed" then info.red
                     else info.blue
                     end

    "#{colorized_info} :: #{build_time}"
  end

  def calculate_time(finished)
    if finished
      duration(Time.now - Time.parse(finished))
    else
      "Not built yet"
    end
  end

  def duration(time)
    secs  = time.to_int
    mins  = secs / 60
    hours = mins / 60
    days  = hours / 24

    if days > 0
      "#{days} days and #{hours % 24} hours ago"
    elsif hours > 0
      "#{hours} hours and #{mins % 60} minutes ago"
    elsif mins > 0
      "#{mins} minutes and #{secs % 60} seconds ago"
    elsif secs >= 0
      "#{secs} seconds ago"
    end
  end

end
