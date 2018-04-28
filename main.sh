#! /bin/bash

# ****************************************************************************************
# Fichier 		: main.sh
# Auteur 		: ledee.maxime@gmail.com, steph.levon@wanadoo.fr
# But du fichier 	:  
# Exécution 		: ./main.sh [--users] [--repatriations] [--strategies] [--report]
# ****************************************************************************************

#################################
#    Initialisation (CONSTANTES)
#################################
USAGE="Usage settings :\
\t $0 \n\
\t $0 [1] [--users] \n\
\t $0 [2] [--repatriations] \n\
\t $0 [3] [--strategies] \n\
\t $0 [4] [--report] \n\
\t $0 [--help] [-h] \n\
\t $0 [--version] [-v] \n\
\t $0 [--get-data] (idStrategie)"
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
	dir_report=${DIR}"/Reports"
	dir_tmpReport=${dir_report}"/tmp"
	mkdir -p ${DIR}"/Data" ${DIR}"/Log" ${dir_report}
	scriptGestionUsers=${DIR}"/Bin/gestion_users.sh"
	scriptGestionRepatriations=${DIR}"/Bin/gestion_repatriations.sh"
	scriptGestionStrategies=${DIR}"/Bin/gestion_strategies.sh"
	fileListStrategies=${DIR}"/Data/list_strategies.txt"
	fileListUsers=${DIR}"/Data/list_users.txt"
	fileListRepatriations=${DIR}"/Data/list_repatriations.txt"
	fileLog=${DIR}"/Log/get_data.log"
	logFileTmp="log_wget.tmp"
	dir_modelReport="${dir_report}/.model"
}

# Display the main menu. 4 choices are available.
function displayMainMenu {
	echo "displayMainMenu function called"
	choice=`zenity --list --title="Main menu" --text="Select a choice :" --width=320 --height=230 \
		--column="" --column="Description" \
		1 "Manage users" \
		2 "Manage repatriations" \
		3 "Manage strategies" \
		4 "Generate a report"\
		5 "Quit"`

	case $choice in
		1)
			echo "Choice 1 selected : Gestion de la liste des utilisateurs (./Bin/gestion_users.sh executed)"
			exec ${scriptGestionUsers}
			;;
		2)
			echo "Choice 2 selected : Gestion de la liste des rapatriements (./Bin/gestion_repatriations.sh executed)"
			exec ${scriptGestionRepatriations}
			;;
		3)
			echo "Choice 3 selected : Gestion de la liste des stratégies (./Bin/gestion_strategies.sh executed)"
			exec ${scriptGestionStrategies}
			;;
		4)
			echo "Choice 4 selected : Génération d'un rapport (displayMenuGenerationReport function called)"
			displayMenuGenerationReport
			;;
		5)
			echo "Good bye"
			;;
		*)
			echo "Canceled"
			;;
	esac
}

# Display the menu to generate a report based on a user and/or a period.
function displayMenuGenerationReport {
	echo "displayMenuGenerationReport function called"

	listUsers=$(cat ${fileListUsers} | tr "\n" "," | sed "s/,$//")

	infosReport=`yad --width=400 --center --separator="#" --title="Generate Report" --text="Please choose which report you want to generate: You can select one or all users. The start and end dates are optional." \
	--form --item-separator="," --date-format="%d-%m-%Y" \
	--field="Select user :":CB \
	--field="Choose a start date (Optional)":DT \
	--field="Choose an end date (Optional)":DT \
	--field="Select a format of report :":CB \
	"ALL,${listUsers}" "" "" "Document" ` # TODO: "Document,Website,Slides"

	if [ -z "$infosReport" ]
	then
		echo "Canceling"
	else
		echo $infosReport
		local idUser=`echo $infosReport | cut -d# -f1 | cut -d: -f1`
		local dateStart=`echo $infosReport | cut -d# -f2`
		if [ -z $dateStart ]; then
			dateStart="01-01-0001" 
		fi
		local dateEnd=`echo $infosReport | cut -d# -f3`
		if [ -z $dateEnd ]; then
			dateEnd=`date "+%d-%m-%Y"`
		fi
		local typeReport=`echo $infosReport | cut -d# -f 4`
		generateReport ${idUser} ${dateStart} ${dateEnd} ${typeReport}
	fi
	displayMainMenu
}

# Generate a report based on a user and/or a period.
# Arguments: a user, a period (the beginning and the end), a type of report (website, document or slide).
# TODO: mettre un lien symbolique cliquable pour la var $destFile
# Rappel format d'un log :
# $date;$idUser;$lastNameUser;$firstNameUser;$mailUser;$destRepatriation;$protoc;$sourceRepatriation;$idStatus;$status;$taille
function generateReport {
	echo "generateReport function called"
	local listIdUser=$1
	local dateStart=$2
	local dateEnd=$3
	local typeReport=$4
	echo -e "\t listIdUser : $listIdUser"
	echo -e "\t dateStart : $dateStart"
	echo -e "\t dateEnd : $dateEnd"
	echo -e "\t typeReport : $typeReport"
	
	########
	# Init #
	########
	mkdir ${dir_tmpReport}
	cp ${dir_modelReport}/${typeReport}/* ${dir_tmpReport}/
	mkdir -p ~/texmf/tex/latex/local/
	cp ${dir_tmpReport}/pgf-pie.sty ~/texmf/tex/latex/local/
	
	###################################
	# Filtrage selon la date de début #
	# et la date de fin               #
	###################################
	tmp_fileDateFilter=${dir_tmpReport}/dateFiltre.tmp
	while read ligne
	do
		dateJMY=`echo ${ligne} | cut -d " " -f1 `
		newFormatDate=`echo $dateJMY | sed 's/\(.*\)-\(.*\)-\(.*\)/\3\2\1/'`
		newFormatDateStart=`echo $dateStart | sed 's/\(.*\)-\(.*\)-\(.*\)/\3\2\1/'`
		newFormatDateEnd=`echo $dateEnd | sed 's/\(.*\)-\(.*\)-\(.*\)/\3\2\1/'`
		echo -e "\n newFormatDate : $newFormatDate"
		echo -e "newFormatDateStart : $newFormatDateStart"
		echo -e "newFormatDateEnd : $newFormatDateEnd"
		if [[ "$newFormatDate" -gt "$newFormatDateStart" && "$newFormatDate" -lt "$newFormatDateEnd" ]]; then
			echo "${ligne}" >> ${tmp_fileDateFilter}
		fi
	done < ${fileLog}
	echo "tmp_fileDateFilter : $tmp_fileDateFilter"
	
	########
	# Init #
	########
	tex_modelStart="${dir_tmpReport}/model_start.tex"
	tex_modelSummaryForALLuser="${dir_tmpReport}/model_summaryForALLuser.tex"
	tex_modelOneUser="${dir_tmpReport}/model_oneUser.tex"
	tex_modelEnd="${dir_tmpReport}/model_end.tex"
	tex_multipleUsers="${dir_tmpReport}/multipleUsers.tex"	
	userName=`exec ${scriptGestionUsers} --get-name ${listIdUser} | tail -n 1`  # Appel fonction située dans un autre script
	if [[ "$listIdUser" == "ALL" ]]; then
		listIdUser=`cut -f2 -d";" ${tmp_fileDateFilter} | sort | uniq`
		userName="ALL"
	elif [ -z `cut -f2 -d";" ${tmp_fileDateFilter} | grep ${listIdUser} | uniq ` ]; then
		listIdUser=""
	fi
	tex_finalResults="${dir_tmpReport}/${userName}_${dateStart}_${dateEnd}.tex"
	file_finalResults="${userName}_${dateStart}_${dateEnd}"
	if [ -f ${dir_report}/${tex_finalResults}.pdf ]; then     # improbable mais bon  :D
		echo "Le fichier existe déjà."
		break
	fi

	echo -e "\n\t\t listIdUser : $listIdUser \n\n"

	
	######################################################
	# Parcours list users :                              #
	# 1 loop if a user defined has been selected,        #
	# several loops if the value "ALL" has been selected #
	######################################################
	# Using tex_multipleUsers file #
	################################
	i=0
	nbFtpTotal=0
	nbHttpTotal=0
	nbEchecTotal=0
	nbReussiteTotal=0
	for currentIdUser in ${listIdUser[*]}
	do
		echo -e "listIdUser[${i}] : ${currentIdUser}"

		#if [ -f $tmp_fileDateFilter ]; then
		#	break;
		#fi
		
		#########################
		# Filtrage selon l'user #
		#########################
		local currentUserName=`exec ${scriptGestionUsers} --get-name ${currentIdUser} | tail -n 1`  # Appel fonction située dans un autre script
		echo -e "1/ User is : $currentUserName (id: $currentIdUser)"
		tmp_fileCurrentUser=${dir_tmpReport}/${currentIdUser}.tmp
		cat ${tex_modelOneUser} >> ${tex_multipleUsers}
		sed -i -e "s/__CURRENT_USER__/${currentUserName} (id: ${currentIdUser})/" ${tex_multipleUsers}
		grep ";${currentIdUser};${currentUserName};" ${tmp_fileDateFilter} > ${tmp_fileCurrentUser}
		
		#############
		# getOneLog #
		#############
		nbFtp=0
		nbHttp=0
		nbEchec=0
		nbReussite=0
		codeTex_RapatriementsReussis=" "
		codeTex_RapatriementsEchoues=" "
      
		while IFS=";" read date idUser lastNameUser firstNameUser mailUser destRepatriation protoc sourceRepatriation idStatus status taille
		do
			destRepatriation=`echo "$destRepatriation" | sed 's.\/.\\\\/.g' | sed 's.\_.\\\\\\\\_.g' `
			sourceRepatriation=`echo "$sourceRepatriation" | sed 's.\/.\\\\/.g' | sed 's.\_.\\\\\\\\_.g' `
			date=`echo $date | cut -d" " -f1`
			echo -e "\n\
				Date : $date\n\
				idUser :\t $idUser\n\
				lastNameUser :\t $lastNameUser\n\
				firstNameUser :\t $firstNameUser\n\
				mailUser :\t $mailUser\n\
				destRepatriation :\t $destRepatriation\n\
				protoc :\t $protoc\n\
				sourceRepatriation :\t $sourceRepatriation\n\
				idStatus :\t $idStatus\n\
				status :\t $status\n\
				taille :\t $taille\n\n"
				
			if [[ "$protoc" == "ftp" ]]; then
				nbFtp=$((nbFtp+1))
				nbFtpTotal=$((nbFtpTotal+1))
			elif [[ "$protoc" == "http" ]]; then
				nbHttp=$((nbHttp+1))
				nbHttpTotal=$((nbHttpTotal+1))
			fi
			
			if [[ $status =~ "réussie" ]]; then
				nbReussite=$((nbReussite+1))
				nbReussiteTotal=$((nbReussiteTotal+1))
				codeTex_RapatriementsReussis=" ${codeTex_RapatriementsReussis} $date \& $sourceRepatriation \& $destRepatriation \& $taille \\\\\\\\ "
			else
				nbEchec=$((nbEchec+1))
				nbEchecTotal=$((nbEchecTotal+1))
				codeTex_RapatriementsEchoues=" ${codeTex_RapatriementsEchoues} $date \& $sourceRepatriation \& $status \\\\\\\\ "
			fi
		done < ${tmp_fileCurrentUser}
		
		###################
		# Graph. protocol FOR ONE USER #
		###################
		echo "nbFtp : $nbFtp"
		echo "nbHttp : $nbHttp"
		sed -i "s@TO-SUBSTITUTE-PROTOCOL@${nbFtp}\/ftp, ${nbHttp}\/http@" ${tex_multipleUsers}
		
		########################
		# Graph. FAILL/SUCCESS FOR ONE USER #
		########################
		nbTentativesUser=$((nbEchec+nbReussite))
		echo "nbTentativesUser : $nbTentativesUser"
		echo "nbReussite : $nbReussite"
		echo "nbEchec : $nbEchec"
		sed -i "s@TO-SUBSTITUTE-NB-TOTAL-DL@${nbTentativesUser}@" ${tex_multipleUsers}
		sed -i "s@TO-SUBSTITUTE-FAIL-SUCCESS@${nbReussite}\/SUCCESS, ${nbEchec}\/FAIL@" ${tex_multipleUsers}
		
		########################
		# Tab. Repatriation OK FOR ONE USER #
		########################
		if [ "$nbReussite" -ge "1" ]
		then
			sed -i "s@TO-SUBSTITUTE-LIST-SUCCESS@${codeTex_RapatriementsReussis}@" ${tex_multipleUsers}
		else
			sed -i "s@TO-SUBSTITUTE-LIST-SUCCESS@\\\multicolumn{4}{|c|}{Aucun rappatriements réussis trouvés} \\\\\\\\@" ${tex_multipleUsers}
		fi
		
		########################
		# Tab. Repatriation KO FOR ONE USER#
		########################
		if [ "$nbEchec" -ge "1" ]
		then
			sed -i "s@TO-SUBSTITUTE-LIST-FAIL@${codeTex_RapatriementsEchoues}@" ${tex_multipleUsers}
		else
			sed -i "s@TO-SUBSTITUTE-LIST-FAIL@\\\multicolumn{3}{|c|}{Aucun rappatriements échoués trouvés} \\\\\\\\@" ${tex_multipleUsers}
		fi
		
		chmod 777 ${tex_multipleUsers}

		i=$((i+1))
	done
	echo "$i idUser(s) distinct(s) trouvés in log file (${fileLog}) durant la date de début et de fin"
	
	########################
	# Using tex_modelStart #
	########################
	echo "tex_finalResults = $tex_finalResults"
	cat ${tex_modelStart} >> ${tex_finalResults}
	chmod 777 ${tex_finalResults}
	sed -i "s@TO-SUBSTITUTE-NAME-USER@${userName}@" ${tex_finalResults}
	sed -i "s@TO-SUBSTITUTE-DATE-START@${dateStart}@" ${tex_finalResults}
	sed -i "s@TO-SUBSTITUTE-DATE-END@${dateEnd}@" ${tex_finalResults}


	if [ "$i" -eq "0" ]; then
		sed -i "s@\\\\tableofcontents@@" ${tex_finalResults}
		echo "Aucun log trouvé correspondant à vos critères de recherche" >> ${tex_finalResults}
	else
		####################################
		# Using tex_modelSummaryForALLuser #
		####################################
		if [[ "$userName" == "ALL" ]]; then
			cat ${tex_modelSummaryForALLuser} >> ${tex_finalResults}
			chmod 777 ${tex_finalResults}
		
			###################
			# Graph. protocol FOR ALL USERS #
			###################
			echo "nbFtpTotal : $nbFtpTotal"
			echo "nbHttpTotal : $nbHttpTotal"
			sed -i "s@TO-SUBSTITUTE-PROTOCOL-ALL@${nbFtpTotal}\/ftp, ${nbHttpTotal}\/http@" ${tex_finalResults}
		
			########################
			# Graph. FAILL/SUCCESS FOR ALL USERS #
			########################
			nbTentativesTotales=$((nbEchecTotal+nbReussiteTotal))
			echo "nbReussiteTotal : $nbReussiteTotal"
			echo "nbEchecTotal : $nbEchecTotal"
			sed -i "s@TO-SUBSTITUTE-NB-TOTAL-DL@${nbTentativesTotales}@" ${tex_finalResults}
			sed -i "s@TO-SUBSTITUTE-FAIL-SUCCESS@${nbReussiteTotal}\/SUCCESS, ${nbEchecTotal}\/FAIL@" ${tex_finalResults}
		fi
	fi
	
	###########################
	# Using tex_modelEnd file #
	###########################
	cat ${tex_multipleUsers} >> ${tex_finalResults}
	chmod 777 ${tex_finalResults}
	cat ${tex_modelEnd} >> ${tex_finalResults}
	chmod 777 ${tex_finalResults}
	
	#############################
	# Generation du fichier PDF #
	#############################
	pdflatex ${tex_finalResults}
	pdflatex ${tex_finalResults}
	
	####################
	# Delete tmp files #
	####################
	mv ${file_finalResults}.pdf ${dir_report}
	mv ${tex_finalResults} ${dir_report}
	rm -rf ${dir_tmpReport}
	rm -f ${file_finalResults}.*
}

# Perform the repatriation
# Argument: Strategy ID's
# Notes personnelles: plusieurs facons pour vérifier et tester un rapatriement
#			1/	ftp .... << BYEBYE
#					newer
#				BYEBYE
#			2/      rsync
#			3/	mirror.pl
function getData {
	echo "getData function called"
	
	local idStrategy=$1
	local strategyLine=`grep ^${idStrategy}: ${fileListStrategies}`
	if [ -z "${strategyLine}" ]
	then
		echo "ERROR: Strategy ID's does not exist"
		exit 1
	fi
	local idUser=`echo ${strategyLine} | cut -f 2 -d":"`
	local idRepatriation=`echo ${strategyLine} | cut -f 3 -d":"`
	local periodicity=`echo ${strategyLine} | cut -f 4 -d":"`
	local isToLog=`echo ${strategyLine} | cut -f 5 -d":"`
	
	local repatriationLine=`grep ^${idRepatriation}: ${fileListRepatriations}`
	local destRepatriation=`echo ${repatriationLine} | cut -f 2 -d":"`
	local protocolRepatriation=`echo ${repatriationLine} | cut -f 3 -d":"`
	local serverRepatriation=`echo ${repatriationLine} | cut -f 4 -d":"`
	local remoteDirRepatriation=`echo ${repatriationLine} | cut -f 5 -d":"`
	local remoteFilesRepatriation=`echo ${repatriationLine} | cut -f 6 -d":"`
	
	local userLine=`grep ^${idUser}: ${fileListUsers}`
	local lastNameUser=`echo ${userLine} | cut -f 2 -d":"`
	local firstNameUser=`echo ${userLine} | cut -f 3 -d":"`
	local mailUser=`echo ${userLine} | cut -f 4 -d":"`
	
	echo -e "\t idStrategy : $idStrategy"
	echo -e "\t idUser : $idUser"
	echo -e "\t idRepatriation : $idRepatriation"
	echo -e "\t periodicity : $periodicity"
	echo -e "\t isToLog : $isToLog"
	destRepatriation=Data/${destRepatriation}
	echo -e "\t destRepatriation : $destRepatriation"
	echo -e "\t protocolRepatriation : $protocolRepatriation"
	echo -e "\t serverRepatriation : $serverRepatriation"
	echo -e "\t remoteDirRepatriation : $remoteDirRepatriation"
	echo -e "\t remoteFilesRepatriation : $remoteFilesRepatriation"
	echo -e "\t lastNameUser : $lastNameUser"
	echo -e "\t firstNameUser : $firstNameUser"
	echo -e "\t mailUser : $mailUser"

	#echo -e "telechargement de : ${protocolRepatriation}://${sourceRepatriation} \n"
	sourceRepat=${protocolRepatriation}://${serverRepatriation}/${remoteDirRepatriation}/${remoteFilesRepatriation}
	echo -e "\t sourceRepat : ${sourceRepat} \n"

	if [[ "$protocolRepatriation" == "ftp" ]]
	then
		# TODO: use rsync
		echo "check ftp : OK"
		wget --timestamping \
			--progress=bar \
			--level=1 \
			--append-output ${logFileTmp} \
			--directory-prefix ${destRepatriation} \
			--tries=45 \
			--no-parent \
			${sourceRepat}
			#--no-remove-listing \
			#--quota=1k
		status=$?
		if [[ "$isToLog" == "yes" ]]
		then
			setLogFromWget ${idUser} ${lastNameUser} ${firstNameUser} ${mailUser} ${destRepatriation} ${sourceRepat} ${status} ${remoteFilesRepatriation}
		fi
	elif [[ "$protocolRepatriation" == "http" ]]
	then
		echo "check http : OK"
		wget --timestamping \
			--progress=bar \
			--level=1 \
			--append-output ${logFileTmp} \
			--directory-prefix ${destRepatriation} \
			--tries=45 \
			--no-parent \
			${sourceRepat}
			#--no-remove-listing \
			#--quota=1k
		status=$?
		if [[ "$isToLog" == "yes" ]]
		then
			setLogFromWget ${idUser} ${lastNameUser} ${firstNameUser} ${mailUser} ${destRepatriation} ${sourceRepat} ${status} ${remoteFilesRepatriation}
		fi
	elif [[ "$protocolRepatriation" == "local" ]]
	then
		echo ""
	fi
	
	if [ -f ${logFileTmp} ]
	then
		rm ${logFileTmp}
	fi
}

# Check if file to download is not already present in local repertory.
function checkLastFile {
	echo "checkLastFile function called"
}

# Generate/update a log file.
# La variable $RES peut prendre differentes valeurs (https://gist.github.com/cosimo/5747881) :
#  - Téléchargement réussie (${taille})
#  - Fichier distant pas plus récent que le fichier local
#  - Generic error code
#  - Parse error—for instance
#  - File I/O error
#  - Network failure
#  - SSL verification failure
#  - Username/password authentication failure
#  - Protocol errors
#  - Server issued an error response (Répertoire ou Fichier source inexistant)
#  - Others errors
# Format of one log :
# $date;$idUser;$lastNameUser;$firstNameUser;$mailUser;$destRepatriation;$protoc;$sourceRepatriation;$idStatus;$status;$taille
function setLogFromWget {
	echo "setLog function called"
	local idUser=$1
	local lastNameUser=$2
	local firstNameUser=$3
	local mailUser=$4
	local destRepatriation=$5
	local sourceRepatriation=$6
	local status=$7
	local remoteFilesRepatriation=$8
	local protoc=`echo $sourceRepatriation | cut -d: -f1 `
	
	echo -e "\t idUser : $idUser"
	echo -e "\t lastNameUser : $lastNameUser"
	echo -e "\t firstNameUser : $firstNameUser"
	echo -e "\t mailUser : $mailUser"
	echo -e "\t destRepatriation : $destRepatriation"
	echo -e "\t sourceRepatriation : $sourceRepatriation"
	echo -e "\t protoc : $protoc"
	echo -e "\t remoteFilesRepatriation : $remoteFilesRepatriation"
	echo -e "\t status : $status"

	if [ -f ${logFileTmp} ]
	then
		wgetLog=`tail -3 ${logFileTmp}`
		echo -e "wgetLog = $wgetLog \n"
		case ${status} in
			# No problems occurred :
			"0")
				taille=`du -b ${destRepatriation}/${remoteFilesRepatriation} | cut -d$'\t' -f1`		# en bytes
				echo "taille = $taille"
				if [[ ! -z `echo ${wgetLog} | grep "enregistré"` ]]
				then
					echo "Status : 0 (No problems occurred)"
					RES="0;Téléchargement réussie;${taille}"
				elif [[ ! -z `echo ${wgetLog} | grep "pas plus récent que le fichier local"` ]]
				then
					echo "Status : 0 (No problems occurred) but Fichier distant pas plus récent que le fichier local"
					RES="0;Fichier distant pas plus récent que le fichier local;0"
				fi
				;;
			# Generic error code :
			"1")
				echo "Status : 1 (Generic error code)"
				RES="1;Generic error code;0"
				;;
			# Parse error—for instance :
			"2")
				echo "Status : 2 (Parse error—for instance, when parsing command-line options, the ‘.wgetrc’ or ‘.netrc’...)"
				RES="2;Parse error—for instance;0"
				;;
			# File I/O error :
			"3")
				echo "Status : 3 (File I/O error)"
				RES="3;File I/O error;0"
				;;
			# Network failure :
			"4")
				echo "Status : 4 (Network failure)"
				RES="4;Network failure;0"
				;;
			# SSL verification failure :
			"5")
				echo "Status : 5 (SSL verification failure)"
				RES="5;SSL verification failure;0"
				;;
			# Username/password authentication failure :
			"6")
				echo "Status : 6 (Username/password authentication failure)"
				RES="6;Username/password authentication failure;0"
				;;
			# Protocol errors :
			"7")
				echo "Status : 7 (Protocol errors)"
				RES="7;Protocol errors;0"
				;;
			# Server issued an error response
			"8")
				echo "Status : 8 (Server issued an error response). Répertoire ou Fichier source inexistant"
				RES="8;Server issued an error response (Répertoire ou Fichier source inexistant);0"
				;;
			*)
				echo "Status : > 8 (Others errors)"
				RES="9;Others errors;0"
				;;
		esac
	else
		echo "Error : log file does not exist"
	fi

	date=`date "+%d-%m-%Y %H:%M:%S"`
	echo "$date;$idUser;$lastNameUser;$firstNameUser;$mailUser;$destRepatriation;$protoc;$sourceRepatriation;$RES" >> ${fileLog}
}


#################################
#    Main
#################################

init
if [ $# -lt 1 ]			# less then / est plus petit que
then
	echo "Displaying the main menu"
	displayMainMenu
else
	case $1 in
		1 | "--users")
			echo "Gestion de la liste des utilisateurs (call of ./Bin/gestion_users.sh script)"
			exec ${scriptGestionUsers}
			;;
		2 | "--repatriations")
			echo "Gestion de la liste des rapatriements (call of ./Bin/gestion_repatriations.sh script)"
			exec ${scriptGestionRepatriations}
			;;
		3 | "--strategies")
			echo "Gestion de la liste des stratégies (call of ./Bin/gestion_strategies.sh script)"
			exec ${scriptGestionStrategies}
			;;
		4 | "--report")
			echo "Génération d'un rapport (call of displayMenuGenerationReport function)"
			displayMenuGenerationReport
			;;
		"--get-data")
			if [ -z "$2" ]
			then
				echo "ERROR lors du rapatriement d'un fichier : missing argument"
				exit 1
			elif ! [[ "$2" =~ ^[0-9]+$ ]]
			then
				echo "ERROR lors du rapatriement d'un fichier : second parameter ($2) must be a number"
				exit 1
			else
				echo "Rapatriement d'un fichier (call of getData function)"
				getData $2
			fi
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
			echo -e "ERROR: Invalid argument.\n${USAGE}"
			exit 1
			;;
	esac
fi
