#!/bin/bash

#------------
#note down the starting directory
#------------

startDir=$('pwd')


#------------
#install required programs
#------------

sudo usr/bin/apt-get update
sudo /usr/bin/apt-get install -y curl python3-pip unzip libfreetype6-dev postgresql-common postgresql postgresql-contrib libpq-dev libxml2-dev libxslt1-dev redis-server
# sudo apt-get -y install libfreetype6-dev
# sudo apt-get -y install postgresql-common postgresql postgresql-contrib
# sudo apt-get -y install libpq-dev
# sudo apt-get -y install libxml2-dev libxslt1-dev
# sudo apt-get -y install redis-server


#------------
#get database user info from user - this will be used in the db creation & for environment vars
#------------

echo $'\n\n'
read -p 'Create Postgres Username: ' uservar
passvar=1
passvar2=2
while [ "$passvar" != "$passvar2" ]
do
	read -sp 'Password: ' passvar
	echo
	read -sp 'Re-Enter Password: ' passvar2
	echo
	if [ "$passvar" != "$passvar2" ]; then
		
		echo
		echo "Password mismatch. Try again"
	fi

done
echo $'\n\n'


#------------
#create the database user & create database (db name is 'runestone')
#------------

#create user
sudo -u postgres createuser -d -s $uservar
#set user password
sudo -u postgres psql -c "ALTER USER $uservar WITH PASSWORD '$passvar';"
#create database
sudo -u postgres createdb --owner=$uservar runestone


#------------
#force 'python' command to call python3 instead of erroring out
#------------

sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10


#------------
# Create main RS directory
#------------

/bin/mkdir "$startDir"/Runestone
cd "$startDir"/Runestone


#------------
#install runestone & rsmanage
#------------

/usr/bin/pip3 install runestone


#------------
#dl & setup web2py
#------------

wget http://www.web2py.com/examples/static/web2py_src.zip
unzip web2py_src.zip


#------------
#setup virtualenv
#------------
sudo pip3 install virtualenv
virtualenv $startDir/Runestone/web2py
source $startDir/Runestone/web2py/bin/activate


#------------
#clone the runestone server into web2py & init runestone components
#------------

cd web2py/applications
git clone https://github.com/RunestoneInteractive/RunestoneServer runestone
cd runestone
pip3 install -r requirements.txt
pip3 install -r requirements-dev.txt
sudo pip3 install -e rsmanage


#------------
#clone the book into place
#------------

cd books
git clone https://github.com/RunestoneInteractive/thinkcspy


#------------
#setup environment vars - note I really dont know if this is the best way to do this but it works...
#------------

echo "export WEB2PY_CONFIG=production # or development or test" >> ~/.bashrc
echo "export WEB2PY_MIGRATE=Yes" >> ~/.bashrc
echo "export DBURL=postgresql://$uservar:$passvar@localhost/runestone" >> ~/.bashrc
echo "export TEST_DBURL=postgresql://$uservar:$passvar@localhost/runestone" >> ~/.bashrc
echo "export DEV_DBURL=postgresql://$uservar:$passvar@localhost/runestone" >> ~/.bashrc

export WEB2PY_CONFIG=production # or development or test
export WEB2PY_MIGRATE=Yes
export DBURL=postgresql://$uservar:$passvar@localhost/runestone
export TEST_DBURL=postgresql://$uservar:$passvar@localhost/runestone
export DEV_DBURL=postgresql://$uservar:$passvar@localhost/runestone


#------------
#init rs database
#------------

cd ~/Runestone/web2py/applications/runestone
rsmanage initdb


#------------
#init thinkcspy book - just to have something to look at and test
#------------

cd books/thinkcspy
runestone build
runestone deploy


#------------
#create the launcher script
#------------
cd ~/Runestone/web2py

#-------------
## don't ask the user for IP address, ask the computer!
##read -p 'Server IP Address: ' serverIP
#-------------

serverIP=$(ifconfig | grep 'inet ' | sed -n 2p | awk '{print $2}')

echo "
#!/bin/bash
# A simple script to start web2py and the companion scheduler app for building
# books.  Copy these into the main web2py folder and use them there
#
export DBUSER=$uservar
export DBPASS='$passvar'
export DBHOST=localhost
export DBNAME=runestone
echo 'Be sure to activate your virtual environment'
source $startDir/Runestone/web2py/bin/activate
python web2py.py --ip=$serverIP --port=8000 --password='<recycle>' -K runestone --nogui -X  &
" > start.sh

chmod +x start.sh



echo 'Runestone Academy installation Finished!'
echo
echo 'Logout and back in for changes to take effect.'
echo 'Start Runestone by going to '"$startDir"'/Runestone/web2py and type ./start.sh'

#./start
