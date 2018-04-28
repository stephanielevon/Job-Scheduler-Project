#! /bin/bash

# ************************************************************************************
# Fichier 		: gestion_repatriations.sh
# Auteur 		: ledee.maxime@gmail.com, steph.levon@wanadoo.fr
# But du fichier 	:  
# Exécution 		: ./gestion_repatriations.sh [--list] [--add]  [--del]
# ************************************************************************************

#################################
#    Initialisation (CONSTANTES)
#################################
USAGE="Usage:\
\t $0 \n\
\t $0 [1] [--list] [-l] \n\
\t $0 [2] [--add] [-a] \n\
\t $0 [3] [--modif] [-m] \n\
\t $0 [4] [--del] [-d] \n\
\t $0 [--help] [-h] \n\
\t $0 [--version] [-v]"
VERSION=1
AUTHORS="Stéphanie LEVON & Maxime LEDEE"
ORGANISATION="Master Degree Bioinformatics - Rouen University"


#################################
#    Functions
#################################

# Initialisation of variables
function init {
	echo "init function called"
	DIR="$( cd "$( dirname "${0}" )" && pwd )"
	scriptMain=${DIR}"/../main.sh"
	fileListRepatriations=${DIR}"/../Data/list_repatriations.txt"
	fileListStrategies=${DIR}"/../Data/list_strategies.txt"
}

# Display the menu. 3 choices are available.
function displayMenu {
	echo "displayMenu function called"
	choice=`zenity --list --title="Automatized repatriation" --text="Select a choice :" --width=320 --height=240 \
		--column="" --column="Repatriation menu" \
		1 "Display list" \
		2 "Add" \
		3 "Modify" \
		4 "Delete"\
		5 "Back to Main Menu"`
		
		case $choice in
		1)
			echo "Choice 1 selected : Display the list of all repatriations"
			listRepatriations
			;;
		2)
			echo "Choice 2 selected : Add a repatriation"
			addRepatriation
			;;
		3)
			echo "Choice 3 selected : Modify a repatriation"
			modifyRepatriation
			;;	
		4)	
			echo "Choice 4 selected : Delete repatriation(s)"
			delRepatriation
			;;
		5)
			echo "Choice 5 selected : Back to Main Menu"
			exec ${scriptMain} 
			;;

		*)
			echo "Canceled"
			;;
	esac
}

# List the repatriations contained in Data/list_repatriations.txt file
function listRepatriations {
	echo "listRepatriations function called"

	local itemsRepatriations=()
	while IFS=':' read -r idRepatriation destFolder protocol server remoteDir remoteFiles ; do
		itemsRepatriations+=( "$idRepatriation" "$destFolder" "$protocol" "$server" "$remoteDir" "$remoteFiles" )
	done < <(cat $fileListRepatriations)

	yad --title="Automatized repatriation" --list --center --text="Display repatriation" --width=600 --height=300 \
			--column="Id" --column="Destination folder" --column="Protocol" --column="Server" --column="Remote directory" --column="Remote files" \
			"${itemsRepatriations[@]}" \
			--button=Return
	
	echo "Return to Menu"
	displayMenu
}

# Add one repatriation in Data/list_repatriations.txt
function addRepatriation {
	echo "addRepatriation function called"
	newRepatriation=`yad --title="Add a repatriation" --width=900 --title="" --center --text="Please enter your details:" --separator=":" \
		--form \
		--field="Destination folders -> ./Data/" \
		--field="Protocol ":CB \
		--field="Server + Remote directory " \
		--field="Remote files " \
		"NCBI/Drosophila_melanogaster/" "ftp!http" "ftp.ncbi.nih.gov:/genomes/Drosophila_melanogaster/RELEASE_5_48/CHR_2/" "NT_033778.faa"`
	getNewId
	if ! [ -z "$newRepatriation" ]
	then
		chmod +w ${fileListRepatriations}
		newDestinationFolder=`echo $newRepatriation | cut -d : -f 1`
		newProtocol=`echo $newRepatriation | cut -d : -f 2`
		newServer_RemoteDir=`echo $newRepatriation | cut -d : -f 3`
		newRemoteFiles=`echo $newRepatriation | cut -d : -f 4`
		echo "$newId:$newDestinationFolder:$newProtocol:$newServer_RemoteDir:$newRemoteFiles" >> $fileListRepatriations 
		echo "New Repatriation add"
		yad --center --width=400 --title="What next?" --text "A new repatriation has been successfully added. \n You can now add a strategie. \n Click \"Validate\" to return to Main Menu."
		exec ${scriptMain}
	else
		yad --center --width=400 --title="No new repatriation add" --text "No repatriation added. \n Click \"Validate\" to return to Repatriation Menu." 
		displayMenu
	fi
}

function getNewId {
	lastId=$(cat $fileListRepatriations | cut -d : -f 1 | sort -nr | head -n 1 )
	newId=$(($lastId+1))
}

# Modify one repatriation
function modifyRepatriation {
	echo "modifyRepatriation function called"

	listRepatriations=""
	for oneRepatriation in `cat ${fileListRepatriations}`
	do
		local idRepatriation=`echo $oneRepatriation | cut -d":" -f1`
		local destination=`echo $oneRepatriation | cut -d":" -f2`
		local protocol=`echo $oneRepatriation | cut -d":" -f3`
		local server=`echo $oneRepatriation | cut -d":" -f4`
		local remoteDir=`echo $oneRepatriation | cut -d":" -f5`
		local remoteFiles=`echo $oneRepatriation | cut -d":" -f6`
		listRepatriations="${listRepatriations},${idRepatriation}:\t Destination : ${destination} \n\t Protocol : ${protocol} \n\t Server/Remote directory : ${server}/${remoteDir} \n\t Remote files : ${remoteFiles}"
	done
	#listRepatriations=$(cat ${fileListRepatriations} | tr "\n" "," | sed "s/,$//")
	repatriationToModify=`yad --width=400 --height=215 --center --title="Modify repatriation" --separator="#" \
		--text="Please enter your changes:\n(Value will not be changed for unfilled field)" \
		--form --item-separator="," \
		--field="Select repatriation :":CB \
		--field="New destination :" \
		--field="New protocol :":CB \
		--field="New server + remote directory :" \
		--field="New remote files :" \
		"${listRepatriations}" "" ",ftp,http"`
		
		echo $repatriationToModify
		oldRepatriation=`echo $repatriationToModify | cut -d"#" -f 1` 
		idRepatriation=`echo $repatriationToModify | cut -c 1`
		newDestinationFolder=`echo $repatriationToModify | cut -d"#" -f 2`
		newProtocol=`echo $repatriationToModify | cut -d"#" -f 3`
		newServer_RemoteDir=`echo $repatriationToModify | cut -d"#" -f 4`
		newRemoteFiles=`echo $repatriationToModify | cut -d"#" -f 5`
		echo $oldRepatriation
		echo "newDestinationFolder : $newDestinationFolder"
		echo "newProtocol : $newProtocol"
		echo "newServer_RemoteDir : $newServer_RemoteDir"
		echo "newRemoteFiles : $newRemoteFiles"
		newServer=`echo $newServer_RemoteDir | cut -d"/" -f 1`
		newRemoteDir=`echo $newServer_RemoteDir | cut -d"/" -f 2-`
		echo "newServer : $newServer"
		echo "newRemoteDir : $newRemoteDir"
		
		if [ -z "$newDestinationFolder" ]
		then
			echo "pas de valeurs dans destination folder"
			newDestinationFolder=`echo $repatriationToModify | cut -d":" -f 2`
		fi

		if [ -z "$newProtocol" ]
		then 
			echo "pas de valeurs dans new Protocol"
			newProtocol=`echo $repatriationToModify | cut -d":" -f 3`
		fi
		
		if [ -z "$newServer_RemoteDir" ]
		then 
			echo "pas de valeurs dans new Server + Remote Directory"
			newServer=`echo $repatriationToModify | cut -d":" -f 4`
			newRemoteDir=`echo $repatriationToModify | cut -d":" -f 5`
		fi
		
		if [ -z "$newRemoteFiles" ]
		then 
			echo "pas de valeurs dans new Remote Files"
			newRemoteFiles=`echo $repatriationToModify | cut -d":" -f 6`
		fi

		# Remplacer ancienne identité dans le fichier $fileListRepatriation par la nouvelle
		newRepatriation=`echo ${idRepatriation}:${newDestinationFolder}:${newProtocol}:${newServer}:${newRemoteDir}:${newRemoteFiles}`
		echo $newRepatriation 
		sed -i "s#${oldRepatriation}#${newRepatriation}#" ${fileListRepatriations}
		
		yad --center --width=400 \
		--title="Change accepted" \
		--text="Your change has been taken into account. \n  Click \"Validate\" to return to Main Menu." 
		
		exec ${scriptMain}
		chmod 700 ${fileListRepatriations}
}

# Delete one or many repatriation(s) in Data/list_repatriations.txt
function delRepatriation {
	echo "delRepatriation function called"
	local listRepatriationsToDel=`zenity --list --checklist --separator=" " --text="Select repatriation(s) to delete :" --width=500 --height=300\
			--column="" --column="Repatriations" \
			$(sed s/^/FALSE\ / ${fileListRepatriations})`
	if ! [ -z "$listRepatriationsToDel" ]
	then
		for repatriation in `echo $listRepatriationsToDel`
		do
			local idRepatriation=`echo ${repatriation} | cut -f 1 -d":"`
			if [ "$(cut -f 3 -d":" ${fileListStrategies} | grep ${idRepatriation})" ]
			then
				zenity --warning --width=500 --height=50 \
					--text "ID repatriation's is used in list strategies's. Please remove the strategy containing the repatriation ID's (${idRepatriation}), then come back here to remove it"
				exec ${scriptMain}
			else
				echo "Removing of repatriation : ${repatriation}"
				sed -i "\?${repatriation}?d" ${fileListRepatriations}
				chmod +w ${fileListRepatriations}
				yad --center --width=400 --title="What next?" --text "Repatriation has been successfully deleted. \n Click \"Validate\" to return to Main Menu." 
				exec ${scriptMain}
			fi
		done
	else
		yad --center --width=400 --title="No repatriation deleted" --text "No repatriation deleted. \n Click \"Validate\" to return to Repatriation Menu." 
		displayMenu
	fi
}


########################
#    Main 
########################

init
if [ $# -lt 1 ]
then
	echo "Displaying the Repatriation Management menu"
	displayMenu
else
	case $1 in
		1 | "--list" | "-l")
			echo "List of repatriations (call of listRepatriations function)"
			listRepatriations
			;;
		2 | "--add" | "-a")
			echo "Add a repatriation (call of addRepatriation function)"
			addRepatriation
			;;
		3 | "--modif" | "-m")
			echo "Modify a repatriation (call of modifyRepatriation function)"
			modifyRepatriation
			;;
		4 | "--del" | "-d")
			echo "Delete a repatriation (call of delRepatriation function)"
			delRepatriation
			;;
		"-h" | "--help")
			echo -e ${USAGE}
			exit 1
			;;
		"-v" | "--version")
			echo -e "VERSION: ${VERSION}\nAUTHORS: ${AUTHORS}\nORGANISATION: ${ORGANISATION}"
			exit 1
			;;
		*)
			echo -e "Invalid argument.\n${USAGE}"
			exit 1
			;;
	esac
fi
