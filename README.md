# centkins
CentOS7 based Jenkins container

* This was a quick and dirty way of putting together a CentOS7 Jenkins container that can build an RPM from Python 3.8.8.
  * The main use case is for deploying the Python install to a RHEL/CENTOS 7.9 box.
  * Most of this code came from the official Jenkins Docker file with "hacks" put in for my own needs.
  * * I added dependencies to build the Pyton installer to the container.
  * * If I didn't have additional dependencies, I would have just used the container provided by Jenkins.
* The Jenkins pipeline job uses OSpackage to create the RPM.

To run this you need Docker and docker-compose installed
* docker-compose up --build

Once Jenkins is up and running, create a new pipeline job and use the following code for the pipeline:
* https://github.com/kevingigiano/centkins/blob/master/job/jenkins_pipline
* The should be changed to checkout the build.gradle file

