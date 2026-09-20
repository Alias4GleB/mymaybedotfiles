#!/usr/bin/bash

# read user input and save it in variable INPUT

read -r INPUT

#read password from the file pass.txt and save it in var PASS

PASS=$(cat /home/glebespalov/screenlockpass/pass.txt)

# compare and end the program false if they are not the same

if [ "$PASS" != "$INPUT" ]
then
    echo "wrong"
    exit 1
  #  read -r INPUT
   # PASS=$(cat /home/glebespalov/screenlockpass/pass.txt)
fi

echo "correct"
exit 0
