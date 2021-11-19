# centkins
CentOS7 based Jenkins container

* This was a quick and dirty way of putting together a CentOS7 Jenkins container that can build an RPM from Python 3.8.8.
  * The main use case is for deploying to a RHEL/CENTOS 7.9 box.
  * Otherwise, I would have just used the container provided by Jenkins.
  * Most of this code came from the official Jenkins Docker file with "hacks" put in for my own needs.
* The Jenkins pipeline job uses OSpackage to create the RPM.

To run this you need Docker and docker-compose installed
* docker-compose up --build

