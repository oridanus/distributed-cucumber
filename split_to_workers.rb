require 'find'
require 'fileutils'

dir = ARGV[0]
number_of_workers = ARGV[1].to_i

cucumber_tags_param = '--tags ~@not_ready'

def prepend_to_file(file, line)
  f = File.open(file, "r+")
  lines = f.readlines
  f.close

  lines = ["#{line}\n"] + lines

  output = File.new(file, "w")
  lines.each { |line| output.write line }
  output.close
end

def get_number_of_scenarios_in_feature(output)
  scenarios_line = output.split(/\n+/).detect  do | line |
    line =~ /\d* scenario.*\(.*\)/
  end
  scenarios_line ? scenarios_from_scenarios_line(scenarios_line) : 0
end

def scenarios_from_scenarios_line(scenarios)
  scenarios.split('scenarios')[0].to_i
end

def next_worker(current_worker, workers_scenarios_count, steps_per_worker)
  iterations = 0
  current_worker = next_round_robin(current_worker, workers_scenarios_count.size)
  while workers_scenarios_count[current_worker] > steps_per_worker and
      iterations <= workers_scenarios_count.size-1
    current_worker = next_round_robin(current_worker, workers_scenarios_count.size)
    iterations+=1
  end

  if iterations > workers_scenarios_count.size
    raise 'all workers are full!'
  end
  current_worker
end

def next_round_robin(index, max_size)
  (index + 1) % max_size
end

def count_scenarios(feature_file, cucumber_tags)
  output = `cucumber #{feature_file} #{cucumber_tags} --dry-run`
  get_number_of_scenarios_in_feature(output)
end

def features_files_to_scenarios_count(feature_files, cucumber_tags)
  Hash[ *feature_files.collect { |feature_file| [ feature_file, count_scenarios(feature_file, cucumber_tags) ] }.flatten ]
end

def total_number_of_scenarios(features_files_to_scenarios_count)
  features_files_to_scenarios_count.values.inject(:+)
end

feature_files = Find.find(dir).select { |file| file.end_with? 'feature' }
features_files_to_scenarios_count = features_files_to_scenarios_count(feature_files, cucumber_tags_param)
total_number_of_scenarios = total_number_of_scenarios(features_files_to_scenarios_count)
scenarios_per_worker = (total_number_of_scenarios.to_f / number_of_workers).ceil
workers_scenarios_count = Array.new(number_of_workers, 0)
current_worker = 0

feature_files.shuffle.each do |feature|
  scenarios = features_files_to_scenarios_count[feature]
  if scenarios > 0
    prepend_to_file(feature, "@worker_#{current_worker+1}")
    workers_scenarios_count[current_worker] += scenarios
    current_worker = next_worker(current_worker, workers_scenarios_count, scenarios_per_worker)
  end
end

puts 'finished adding workers tags to feature files'
puts 'scenarios per workers:'
workers_scenarios_count.each_with_index { |scenarios, worker| puts "@worker_#{worker+1} : #{scenarios}" }

