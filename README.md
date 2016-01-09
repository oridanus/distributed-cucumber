# distributed-cucumber
Speed up Cucumber tests by running on several machines


## how?
At [Traiana](http://traiana.com/), we use Jenkins to run the cucumber tests suite.
To run much faster - tests can be distributed using a setup as follows

### High level

This is an example of jenkins setup, splitting to 7 workers:

![Alt text](jenkins.png?raw=true "7 Jobs")

"Orchestrator" is the entry-point job.

Orchestrator will call the "Splitter" job. the splitter does his little magic and divides the features files into slices, where each slice will get a cucumber tag running from @worker_1, @worker_2, ... , @worker_N .

Next the Orchestrator will run the "workers" jobs - T1, ...,Tn in parallel (using - [Build Flow Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Build+Flow+Plugin) )

After all of the workers jobs are done, Orchestrator will call the "Join" job, which will take all the reports of the workers jobs and join them to the final report.

### Prerequisite
 
1. Jenkins installation with [Build Flow Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Build+Flow+Plugin)
2. ruby installed
3. 

### Splitter

the splitter is using [split_to_workers.rb](https://github.com/omyd/parallel-cucumber/blob/master/split_to_workers.rb) ruby script.
the script gets as parameters:
1. the root directory in which your features files are located
2. number of workers

It uses dry-run to count how many scanrios we have in total (excluding @not_ready tag) 
Then iterate over all the feature files, prepending tags, such as @worker_X, to the first line of each file.
It uses a round-robin algorithm, to balance the workers to have simillar amount of scenarios each.

Then pushes the resulting feature files with the tags to a temporary git branch, let's call it "parallel-branch"

### Workers

the workers will checkout out "parallel-branch" the run your 