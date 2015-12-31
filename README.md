# parallel-cucumber
Speed up Cucumber tests by running parallel on several machines


## how?
We at Traiana use Jenkins to run the cucumber tests suite.
To run much faster - tests can be splitted using a simple setup as follows

### High level

This is an example of jenkins setup, splitting to 7 workers:

![Alt text](jenkins.png?raw=true "7 Jobs")

"Orchestrator" is the entry-point job.

Orchestrator will call the "Splitter" job. the splitter does his little magic and divides the features files into slices, where each slice will get a cucumber tag running from @worker_1, @worker_2, ... , @worker_N .

Next the Orchestrator will run the "workers" jobs - T1, ..., Tn in parallel (using - [Build Flow Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Build+Flow+Plugin) )

After all of the workers jobs are done, Orchestrator will call the "Join" job, which will take all the reports of the workers jobs and join them to the final report.

### Splitter

the splitter is using [add_workers_tags.rb](https://github.com/omyd/parallel-cucumber/blob/master/add_workers_tags.rb) ruby script.
the script gets as parameters

