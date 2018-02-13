#!/usr/local/bin/fish

function jgroot
	set -g grootDir (getGitRootDir) 
	if [ ! -z "$grootDir" ]
		cd $grootDir
	else
	  echo "not git repository. not support"  
	end
end

function getGitRootDir
	set -g curDir (pwd)
	while [ $curDir != "/" ]
		if [ -d "$curDir/.git" ]
			echo $curDir
			break
		end
		set -g curDir (echo $curDir|sed -e s'/\/[^\/]*$//')
	end
end


function jgmain
	set -g grootDir (getGitRootDir) 
	if [ ! -z "$grootDir" ]
		set -g projName (cd $grootDir ; ls -d *.xcworkspace | sed -e s'/\.xcworkspace//')
		cd $grootDir/$projName/$projName
	end
end


function autobuild
	set -g grootDir (getGitRootDir) 
	if [ ! -z "$grootDir" ]
		set -g projName (cd $grootDir ; ls -d *.xcworkspace | sed -e s'/\.xcworkspace//')
		if [ $projName = "Here" ]
			python $grootDir/tools/pack/autobuild.py $argv
			# echo "halo $argv"
		else
			echo "not in here project"
		end
	else
		echo "not in here project"	
	end
end


function autoclean
	set -g grootDir (getGitRootDir) 
	if [ ! -z "$grootDir" ]
		set -g projName (cd $grootDir ; ls -d *.xcworkspace | sed -e s'/\.xcworkspace//')
		if [ $projName = "Here" ]
			xcodebuild -workspace "$grootDir/Here.xcworkspace" -scheme Here  -configuration Debug clean
			# python tools/pack/autobuild.py $1
			# echo "halo $argv"
		else
			echo "not in here project"
		end
	else
		echo "not in here project"	
	end
end
