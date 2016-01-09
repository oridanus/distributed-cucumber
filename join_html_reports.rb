require 'nokogiri'
require 'fileutils'

files = ARGV[0].split(',')
joined_file = ARGV[1]
failed_file = ARGV[2]

def read_file(file)
  f = File.open(file, "r+")
  content= f.read
  f.close
  content
end

def write_to_file(file, string)
  f = File.open(file, "w")
  f.write(string)
  f.close
end

def get_html(file)
  Nokogiri::HTML(read_file(file)) do |config|
    config.options = Nokogiri::XML::ParseOptions::NOERROR
  end
end

def get_features_from_html(html)
  html.css("div[class='feature']")
end

def status_node(html)
  html.css("script[type='text/javascript']")[-1]
end

def get_file_status(html)
  status_str = status_node(html).text.split('=')[1]
  Status.from_str(status_str)
end

class Status
  attr_accessor  :total_scenarios
  attr_accessor  :failed_scenarios
  attr_accessor  :passed_scenarios
  attr_accessor  :total_steps
  attr_accessor  :passed_steps

  def self.from_str(status_str)
    status = Status.new
    scenarios_str, steps_str = status_str.split('<br />')
    status.total_scenarios = scenarios_str[/(\d*) scenario/, 1].to_i
    status.failed_scenarios = scenarios_str[/(\d*) failed/, 1].to_i
    status.passed_scenarios = scenarios_str[/(\d*) passed/, 1].to_i

    status.total_steps = steps_str[/(\d*) steps/, 1].to_i
    status.passed_steps = steps_str[/(\d*) passed/, 1].to_i
    status
  end

  def self.from_numbers(total_scenarios, failed_scenarios, passed_scenarios, total_steps, passed_steps)
    status = Status.new
    status.total_scenarios = total_scenarios
    status.failed_scenarios = failed_scenarios
    status.passed_scenarios = passed_scenarios

    status.total_steps = total_steps
    status.passed_steps = passed_steps
    status
  end

  def + (other_status)
    Status.from_numbers(@total_scenarios += other_status.total_scenarios, @failed_scenarios += other_status.failed_scenarios,
                        @passed_scenarios += other_status.passed_scenarios, @total_steps += other_status.total_steps,
                        @passed_steps += other_status.passed_steps)
  end

  def to_s
    "#{total_scenarios} scenarios (#{failed_scenarios} failed, #{passed_scenarios} passed)<br />#{total_steps} steps (#{passed_steps} passed)"
  end
end

def scenario_headings(feature)
  feature.css("h3")
end

def replace_scenarios_counting(feature, scenario_number)
  scenario_headings(feature).each do | scenario_heading |
    original_scenario_number = scenario_heading['id']
    new_scenario_number = "scenario_#{scenario_number}"
    scenario_heading['id'] = new_scenario_number
    feature.css("script").each do |script|
      if script.text.include? original_scenario_number
        script.content = script.content.sub(original_scenario_number, new_scenario_number)
      end
    end
    scenario_number += 1
  end
  scenario_number
end

def build_failed_html(html, failed_file)
  new_html = html.dup
  get_features_from_html(new_html).each do |feature|
    feature.remove unless feature.text.include? 'makeRed'
  end
  puts "Writing failed result to: #{failed_file}"
  write_to_file(failed_file, new_html.to_html)
end

def join(files)
  join_html = get_html(files.first)
  last_feature = get_features_from_html(join_html).last
  total_status = get_file_status(join_html)

  scenario_number = scenario_headings(last_feature).last['id'].split('_')[1].to_i
  files[1..-1].each do |file|
    html = get_html(file)
    get_features_from_html(html).each do |feature|
      scenario_number = replace_scenarios_counting(feature, scenario_number)
      last_feature = last_feature.add_next_sibling(feature)
    end
    total_status = total_status + get_file_status(html)
  end
  status_node(join_html).content = "document.getElementById('totals').innerHTML = \"#{total_status}\";"
  return join_html, total_status
end

join_html, total_status = join(files)
puts "Writing join result to: #{joined_file}"
write_to_file(joined_file, join_html.to_html)
puts total_status
build_failed_html(join_html, failed_file) if(failed_file)