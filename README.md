# parallel-cucumber
Speedup Cucumber tests by running parallel on several machines


## how?
We at Traiana use Jenkins to run the all of the cucumber tests suite.
To run much faster - tests will be splitted using a simple setup as follows

### High level

jenkins jobs, splitting to 7, will look like this:

![jenkins.png]({{site.baseurl}}/jenkins.png)
