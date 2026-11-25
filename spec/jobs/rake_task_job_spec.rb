# frozen_string_literal: true

require "rails_helper"

describe RakeTaskJob do
  let(:calls) { [] }

  before do
    described_class.load_tasks
    calls_made = calls
    Rake::Task.define_task(:rake_task_job_spec, [:months]) do |_task, args|
      args.with_defaults(months: 3)
      calls_made << args[:months]
    end
  end

  after { Rake::Task[:rake_task_job_spec].clear }

  it "runs the task every time the job is performed, with its default arguments" do
    2.times { described_class.perform_now("rake_task_job_spec") }

    expect(calls).to eq([3, 3])
  end

  it "runs a scheduled Decidim task more than once in the same process" do
    expect do
      2.times { described_class.perform_now("decidim_meetings:clean_registration_forms") }
    end.not_to raise_error
  end

  it "raises when the task does not exist" do
    expect { described_class.perform_now("decidim:metrics:all") }.to raise_error(RuntimeError, /Don't know how to build task/)
  end
end
