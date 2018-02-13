#!/bin/bash


function jgroot(){
	grootDir=`getGitRootDir`	
	if [ ! -z "$grootDir" ] ; then
		cd $grootDir
	else
	  echo "not git repository. not support"  
	fi  
}



function getGitRootDir(){
	curDir=`pwd`
	while [ $curDir != "/" ] ; do
		if [ -d "$curDir/.git" ] ; then
			echo $curDir
			break
		fi
		curDir=$(echo $curDir|sed -e s'/\/[^\/]*$//')
	done
}


function jgmain(){
	grootDir=`getGitRootDir`
	if [ ! -z "$grootDir" ] ; then
		projName=$(cd $grootDir ; ls -d *.xcworkspace | sed -e s'/\.xcworkspace//')
		cd $grootDir/$projName/$projName
	fi
}


function autobuild(){
	grootDir=`getGitRootDir`
	if [ ! -z "$grootDir" ] ; then
		projName=$(cd $grootDir ; ls -d *.xcworkspace | sed -e s'/\.xcworkspace//')
		if [ $projName = "Here" ] ; then
			python "$grootDir"/tools/pack/autobuild.py $@
		else
			echo "not in here project"
		fi
	else
		echo "not in here project"	
	fi
}


function autoclean(){
	grootDir=`getGitRootDir`
	if [ ! -z "$grootDir" ] ; then
		projName=$(cd $grootDir ; ls -d *.xcworkspace | sed -e s'/\.xcworkspace//')
		if [ $projName = "Here" ] ; then
			xcodebuild -workspace "$grootDir/Here.xcworkspace" -scheme Here  -configuration Debug clean
			# python tools/pack/autobuild.py $1
			# echo "halo $argv"
		else
			echo "not in here project"
		fi
	else
		echo "not in here project"	
	fi
}



