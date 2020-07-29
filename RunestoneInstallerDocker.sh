#!/bin/bash

#This script is based on the Runestone docker installation video here: https://www.youtube.com/watch?v=y3oeBmRQVf0


#---
#useful commands once things are installed
#---

#start runestone
#docker-compose up -d 

#watch runestone logs
#docker-compose logs --tail 100 --follow

#to get console access to the runestone server
#docker exec -it runestoneserver_runestone_1 /bin/bash
	
	#---
	#when inside of docker console
	#---

	#to get to runestone folder
	#cd applications/runestone

	#add a course (from within runestone folder)
	#rsmanage addcourse

	#rebuild a book(from within runestone/books/<course> folder)
	#runestone build --all deploy






#part of the install requires a reboot to add them to the docker group so mark down whether the user has finished part 1 or not
#with this little hidden file. The user will simply reboot and then re-run the script and it should pick up at the second
#half of the installation
part1File=~/.runestonept1Done

if [ ! -f "$part1File" ]; then
	sudo apt-get update
	sudo apt-get -y install git net-tools docker.io docker-compose npm



	echo $'\n\n'
	passvar=1
	passvar2=2
	while [ "$passvar" != "$passvar2" ]
	do
		read -sp 'Enter a password for the Postgres database: ' passvar
		echo
		read -sp 'Re-Enter Password: ' passvar2
		echo
		if [ "$passvar" != "$passvar2" ]; then
			echo
			echo "Password mismatch. Try again"
		fi

	done
	echo $'\n\n'

	serverIP=$(ifconfig | grep 'inet ' | sed -n 2p | awk '{print $2}')

	echo "export RUNESTONE_HOST=$serverIP" >> ~/.bashrc
	echo "export POSTGRES_PASSWORD=$passvar" >> ~/.bashrc

	sudo systemctl enable docker


	mkdir ~/Runestone
	cd ~/Runestone

	#our version of the server repo includes a docker-compose.override.yml file and 
	#a slightly modified dockerfile as per the instructions in the youtube video
	git clone https://github.com/cromerMHC/RunestoneServer

	#this should not have to point to our version of the components for long - but there
	#is an issue with the audio tours that ours fixes for the time being (7/29/20)
	git clone https://github.com/cromerMHC/RunestoneComponents

	cd ~/Runestone/RunestoneComponents/
	npm install
	npm run build

	cd ~/Runestone/RunestoneServer/


	sudo groupadd docker
	sudo usermod -a -G docker ${USER}

	touch ~/.runestonept1Done
	echo "part 1 installation done. Please restart the system and re-run this installation script to continue with the installation"
	exit
fi

cd ~/Runestone/RunestoneServer
docker build -t runestone/server .

#very occasionally it fails to build properly so make a second attempt 
#(if the first one succeeded this should only add an extra second or so to the install time)
docker build -t runestone/server . 

cd ~/Runestone/RunestoneServer/books
git clone https://github.com/RunestoneInteractive/fopp
	cd ~/Runestone/RunestoneServer/books/fopp
git checkout ac101
cd ~/Runestone/RunestoneServer/

#the configs folder will allow CSV files to be added to auto add studetns/instructors to courses
mkdir ~/Runestone/RunestoneServer/configs

echo "installation complete. Go to the Runestone/RunestoneServer folder and Run 'docker-compose up -d' to start the server"


