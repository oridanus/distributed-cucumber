# parallel-cucumber
Speedup Cucumber tests by running parallel on several machines


## how?
We at Traiana use Jenkins to run the all of the cucumber tests suite.
To run much faster - tests will be splitted using a simple setup as follows

### High level

an example of jenkins jobs, splitting to 7 workers, will look like this:

![Alt text](jenkins.png?raw=true "7 Jobs")

we have the "Orchestrator" which is the entry-point job.

Orchestrator will call the "Splitter" job. the splitter does a little magic and divides the features files into slices, where each slice will get a cucumber tag running from @worker_1, @worker_2, ... , @worker_N

next the Orchestrator is running jobs T1, ..., Tn in parralel (using - [Build Flow Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Build+Flow+Plugin) )


