#!/bin/bash

# This is a rather dumb bash script that I use to simplify the process
# of bootstrapping a new server so ansible can access it

# This script creates an ansible user on the target host

# Call the script using bash ansible_bootstrap.sh hostname.of.server

# Test to see if we can SSH
testssh() {
    ssh $1 "hostname > /dev/null"
    return $?
}

if [[ -z $1 ]]; then
  echo "Please specify the hostname to bootstrap"
  exit 1
fi

TARGETHOST=$1

echo "====================="
echo "Bootstrapping ansible";
echo "====================="

echo "Script prerequisites:"
echo " - This PC must have ssh and ssh-copy-id installed"
echo " - $TARGETHOST must have ssh, sudo and visudo installed"
echo " - You can ssh to $TARGETHOST and use sudo (you may want to ssh-add your key)"
echo " - $TARGETHOST cannot already have a user named 'ansible'"
echo "If all of these aren't met, CTRL+C now"

read -p "Username to use on $TARGETHOST (must have sudo): " TARGETUSERNAME
echo

if [[ -z ${TARGETUSERNAME} ]]; then
  echo "Username is required"
  exit 1
fi

TARGET="${TARGETUSERNAME}@${TARGETHOST}"

echo "Testing SSH connectivity to ${TARGET}."

if ( testssh ${TARGET} ); then
  echo "Success"
else
  echo "Unable to connect to $TARGET. Is your SSH key authorised?"
  exit 1
fi

echo "Creating ansible user"
ssh $TARGET -t "sudo useradd ansible && sudo mkdir /home/ansible && 
                echo 'Creating .ssh/ folder for user' &&
                sudo mkdir /home/ansible/.ssh && sudo chmod 700 /home/ansible/.ssh && sudo chown -R ansible:ansible ~ansible/ && 
                echo 'Setting shell to bash' &&
                sudo chsh -s /bin/bash ansible && 
                echo 'Supply a password for the new ansible user' && 
                sudo passwd ansible"

if [ $? -eq 0 ]; then
  echo "User created"
else
  echo "Failed to create user"
  exit $?
fi

echo "Calling visudo as $TARGET"
ssh $TARGET -t sudo visudo

echo "Copying your SSH public key to ansible@$TARGETHOST"
ssh-copy-id "ansible@$TARGETHOST"

if [ $? -eq 0 ]; then
  echo "Key copied"
else
  echo "Failed to copy key"
  exit $?
fi

echo "If this all worked, you should now be able to ssh ansible@$TARGETHOST and use sudo"
echo "In your ansible playbooks you can now specify user: ansible and sudo: yes"

echo "===="
echo "Done"
echo "===="

