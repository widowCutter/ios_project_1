.SILENT: run set
run:
	cp ./files/file.txt.backup ./files/file.txt
	# MOLE_RC=/home/andrej/Learning/ios/1projekt/files/file.txt dash ./mole.sh -g cgroup1,cgroup2 ./helasdlfsdfsfjskdf.txt
	# MOLE_RC=/home/andrej/Learning/ios/1projekt/files/file.txt dash ./mole.sh -a 2023-03-20 -b 2023-03-25
	MOLE_RC=/home/andrej/Learning/ios/1projekt/files/file.txt dash ./mole.sh list -g cgroup1

set:
	export MOLE_RC=/home/andrej/Learning/ios/1projekt/file.txt
