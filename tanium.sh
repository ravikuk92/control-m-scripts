#!/bin/bash

# Determine OS and set PATH
case $(uname) in
    SunOS)
        PATH=$PATH:/usr/ucb
        ;;
    Linux)
        if [[ -d /usr/ucb ]]; then
            PATH=$PATH:/usr/ucb
        fi
        ;;
    AIX)
        ;;
    *)
        echo "ERROR - Unknown OS"
        exit 2
        ;;
esac

export PATH

# Find configuration data files
confDataFiles=$(find /opt/cma/cmusr /opt/cmagt* /sysu/ctma/cmagt* /opt/ctma/cmagt* /opt/controlm/cmagt* /cntlm/cmagt* /opt/cntlm/cmagt* -name "[Cc][Oo][Nn][Ff][Ii][Gg].dat*" 2> /dev/null)

if [[ "$confDataFiles" != "" ]]; then
    for confData in $confDataFiles; do
        if [[ $(grep -c CTMPERMHOSTS "$confData") -gt 0 ]]; then
            echo "$confData" | grep -v uninstall > /dev/null 2> /dev/null
            if echo "$confData" | grep -q backup_area > /dev/null 2> /dev/null; then
                agOwn=$(stat --format %U "$confData")
                agVer=$(awk '/FIX_NUMBER/{print $2}' "$confData")
                ctmHost=$(awk '/CTMSHOST/{print $2}' "$confData")
                agHome=$(awk '/AGHOME/{print $2}' "$confData" | awk -F":" '{print $6}')
                agOwner=$(awk '/AGENT_OWNER/{print $2}' "$confData" | awk -F":" '{print $2}')
                agMode=$(awk '/AG_MODE/{print $2}' "$confData")
                agProtocol=$(awk '/PROTOCOL_VERSION/{print $2}' "$confData")
                agJavaHome=$(awk '/JAVA_AR/{print $2}' "$confData")
                agJavaVersion=$(awk '/JAVA_VERSION/{print $2}' "$confData" | xargs realpath)
                agLogicalName=$(awk '/LogicalName/{print $2}' "$confData")
                ctmAgentStatus=$(grep ctm_agent_status.dat)
                cmlist=$(grep -c "Succeeded" <<< "$diag_report")
                freeAgHome=$(df -Ph "$agHome" | awk 'NR==2 {print $4}')
                freeTMP=$(df -Ph "/var/tmp" | awk 'NR==2 {print $4}')
                taskExecutedCount=$(echo "$diag_report" | awk '/Execution Ended/ {print $2}')
                agProcess="AG:AT:AW:OK"

                agListener=$(echo "$diag_report" | grep "Agent Listener" | awk -F":" '{print $2}' | grep -c "Running as root")
                agTracker=$(echo "$diag_report" | grep "Agent Tracker" | awk -F":" '{print $2}' | grep -c "Running as root")
                startupServiceState=$(systemctl is-enabled "$agOwn.service")
                startupServiceStatus=$(systemctl is-active "$agOwn.service")

                # Read installed versions
                declare -A moduleVersions=()
                declare -A moduleInstallDate=()
                if [[ -f "$agHome/installed-versions.txt" ]]; then
                    while IFS= read -r line; do
                        module=$(echo $line | awk '{print $1}')
                        version=$(echo $line | awk '{print $3}')
                        installDate=$(echo $line | awk '{print $4}')
                        if [[ "$module" =~ ^[A-Z0-9]+$ && "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                            if [[ -z ${moduleVersions[$module]} ]] || [[ $(echo -e "${moduleVersions[$module]}\n$version" | sort -V | tail -1) == "$version" ]]; then
                                moduleVersions[$module]=$version
                                moduleInstallDate[$module]=$installDate
                            fi
                        fi
                    done < "$agHome/installed-versions.txt"
                fi

                moduleVersionsOutput=""
                for module in "${!moduleVersions[@]}"; do
                    moduleVersionsOutput+="$module (${moduleInstallDate[$module]}): ${moduleVersions[$module]}, "
                done

                # Ping information
                unixPing="OK"
                agPing="OK"
                if [[ $unixPing -lt 1 ]]; then
                    unixPing="NOTOK"
                fi
                if [[ $agPing -lt 1 ]]; then
                    agPing="NOTOK"
                fi

                previousDay=$(date -d "yesterday" +%Y%m%d)
                logFile="$agHome/ctm/dailylog/diag_ctmag_$previousDay.log"
                if [[ -f "$logFile" ]]; then
                    pingInfo=$(grep "EXECUTION ENDED" "$logFile" | tail -1)
                    pingFrom=$(echo "$pingInfo" | awk -F"FROM CONTROL-M SERVER:" '{print $2}' | awk '{print $1}')
                    pingTo=$(echo "$pingInfo" | awk -F"TO LOCAL AGENT:" '{print $2}' | awk '{print $1}')
                    ctmPing="${pingDateTime}:${pingFrom}:${pingTo}"
                else
                    taskExecutedCount="null"
                    ctmPing="NoPingfromCTM"
                fi

                # Output results
                echo "$confData: Version=$agVer, CTMSRV=$ctmHost, AG2SRV=$agProtocol"
                echo "$confData: Persistent=$agPersistent, Mode=$agMode, SSL=$agSSL, Protocol=$agProtocol"
                echo "$confData: JavaSource=$agJavaHome, Java=$agJavaVersion, LogicalName=$agLogicalName"
                echo "$confData: ctm_agent_status=$ctmAgentStatus, TasksExecuted=$taskExecutedCount"
                echo "$confData: InstalledVersions=${moduleVersionsOutput%, }, unixPing=$unixPing, agPing=$agPing"
            fi
        fi
    done
else
    exit 1
fi

exit 0