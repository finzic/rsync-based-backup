#!/bin/bash
FIRST_RESULT=$(wc -l < zero-lines.txt) 
echo "First result is : |$FIRST_RESULT|"
if [ $FIRST_RESULT -eq 0 ]
then
	echo "First Result is equal to 0"
else
	echo "First Result is not equal to 0"
fi
SECOND_RESULT=$(wc -l < five-lines.txt)
echo "Second result is : |$SECOND_RESULT|" 
if [ $SECOND_RESULT -eq 5 ]
then
	echo "Second Result is equal to 5"
else
	echo "Second Result is NOT equal to 5"
fi

