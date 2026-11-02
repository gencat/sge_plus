# frozen_string_literal: true

require "rake"

# Runs a rake task from a Solid Queue recurring task (config/recurring.yml),
# so the scheduled Decidim maintenance tasks run in the worker instead of a
# cron on the Docker host.
#
# Rake::Task#invoke only runs a task once per process, and the worker process
# lives for days, so this uses #execute, which can run again every time. The
# tasks are loaded once per process; :environment is already loaded here.
class RakeTaskJob < ApplicationJob
  queue_as :default

  LOAD_TASKS_LOCK = Mutex.new

  def perform(task_name)
    self.class.load_tasks
    task = Rake::Task[task_name]
    # A fresh arguments object, so tasks that set defaults (with_defaults)
    # get them and nothing is shared between runs.
    task.execute(Rake::TaskArguments.new(task.arg_names, []))
  end

  def self.load_tasks
    LOAD_TASKS_LOCK.synchronize do
      next if @tasks_loaded

      Rails.application.load_tasks
      @tasks_loaded = true
    end
  end
end
