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

workers_scenarios_count = Array.new(number_of_workers, 0)

output = `cucumber --dry-run #{cucumber_tags_param} -r features #{dir}`
total_number_of_scenarios = scenarios_from_scenarios_line(output.split(/\n+/)[-3])

scenarios_per_worker = (total_number_of_scenarios.to_f / number_of_workers).ceil

feature_files = Find.find(dir).select { |file| file.end_with? 'feature'}

current_worker = 0

feature_files.shuffle.each do |feature|
  output = `cucumber #{feature} #{cucumber_tags_param} --dry-run`
  scenarios = get_number_of_scenarios_in_feature(output)
  if scenarios > 0
    prepend_to_file(feature, "@worker_#{current_worker+1}")
    workers_scenarios_count[current_worker] += scenarios
    current_worker = next_worker(current_worker, workers_scenarios_count, scenarios_per_worker)
  end
end

puts 'finished adding workers tags to feature files'
puts 'scenarios per workers:'
workers_scenarios_count.each_with_index { |scenarios, worker| puts "@worker_#{worker+1} : #{scenarios}" }

