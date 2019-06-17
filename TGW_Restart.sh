#!/bin/sh
LOCKFILE=/usr/local/spoken/restarttgw.pid
LOGFILE=/usr/local/spoken/TGW_RESTART_$(date +"%m-%d-%Y").log
#VARIABLE PARAMETERS
#Getting TGW, MSG, DSR, ATT_TTS, TTS, ARR & MON
#TGW HOSTNAME, INSTANCE_NAME, Alphabet, INSTANCE_NUMBER
HOSTNAME=$(hostname); 
#First 3 alpha of HOSTNAME
ZAB=$(cut -c -3  <<< $(hostname))
#TGW INSTANCE_NAME & INSTANCE_NUMBER
TGW_INSTANCE_NAME=$(spoken status here all|grep tgw|awk '{print $4}');
TGW_ALPHAS=$((${#TGW_INSTANCE_NAME}-1));
TGW_INSTANCE_NO=${TGW_INSTANCE_NAME:${TGW_ALPHAS}:1};
#MSG INSTANCE_NAME, Alphabet, INSTANCE_NUMBER
MSG_INSTANCE_NAME=$(spoken status all|grep msg${TGW_INSTANCE_NO}|awk '{print $4}');
MSG_ALPHAS=$((${#MSG_INSTANCE_NAME}));
MSG_INSTANCE_EX=${MSG_INSTANCE_NAME:0:$(expr ${MSG_ALPHAS} - 1)};
#TGW Monitor 
TGW_MON=$(spoken status all|grep "Spoken Servers Monitor"|grep mon|awk '{print $4}');
#TGW Text-to-Speech INSTANCE_ID
ATT_HOSTNAME=$(echo $(hostname)|rev|cut -c 4-|rev)
TTS_INSTANCE_ID=$(spoken status here all|grep "${ATT_HOSTNAME}tts${TGW_INSTANCE_NO}"|awk '{print $4}');
#TGW ATT Text-To-speech INSTANCE_ID
ATT_TTS_INSTANCE_ID=$(spoken status here all|grep att_tts${TGW_INSTANCE_NO}|awk '{print $4}');
#TGW Digital Speech Recognitation
DSR_INSTANCE_ID=$(spoken status all|grep dsr${TGW_INSTANCE_NO}|awk '{print $4}');
#TGW Archieve 
ARR_INSTANCE_ID=$(spoken status here all|grep arr${TGW_INSTANCE_NO}|awk '{print $4}');
#Function to check running TELEPHONY GATEWAY status
ZABBIX_MAIN()
{
if [[ ${ZAB} == clt ]] || [[ ${ZAB} == CLT ]]; then
ssh 10.15.240.122 "zabbix-maint -s $(hostname) -d 90";
ssh 10.15.240.122 "zabbix-maint -s ${MSG_INSTANCE_EX} -d 90";
return 0
elif [[ ${ZAB} == cha ]] || [[ ${ZAB} == CHA ]]; then
ssh 10.15.240.122 "zabbix-maint -s $(hostname) -d 90";
ssh 10.15.240.122 "zabbix-maint -s ${MSG_INSTANCE_EX} -d 90";
return 0
elif [[ ${ZAB} == den ]] || [[ ${ZAB} == DEN ]]; then
ssh 10.15.240.122 "zabbix-maint -s $(hostname) -d 90";
ssh 10.15.240.122 "zabbix-maint -s ${MSG_INSTANCE_EX} -d 90";
return 0
elif [[ ${ZAB} == ash ]] || [[ ${ZAB} == ASH ]]; then
ssh 10.20.254.98 "zabbix-maint -s $(hostname) -d 90";
ssh 10.20.254.98 "zabbix-maint -s ${MSG_INSTANCE_EX} -d 90";
return 0
else
echo "Wrong function ZABBIX_MAIN for HOSTNAME parameter transfer";
exit
fi
}
checkRUNNING_STATUS()
{
if [ -e ${LOCKFILE} ] && kill -0 $(cat ${LOCKFILE}); then
    echo "Script TGW_RESTART already running";
  exit
fi
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}
}
checkACTIVELINE_COUNT()
{
ACTIVE_COUNT=$(grep ACTIVELINE_COUNT $(ls -1tr /usr/local/spoken/logs/TGW* | tail -1)|awk -F, '{print $3}'|tail -1);

if [[ ${ACTIVE_COUNT} > 0 ]] ; then
echo "Current ACTIVELINE_COUNT is ${ACTIVE_COUNT}. Pushing TGW INSTANCE ${TGW_INSTANCE_NAME} to idle" 2>&1 | tee ${LOGFILE}
checkTGWRESTART idle
sleep 30
checkACTIVELINE_COUNT
return 0
else
echo "Current ACTIVELINE_COUNT is ${ACTIVE_COUNT}. Pushing TGW INSTANCE ${TGW_INSTANCE_NAME} to stop" 2>&1 | tee ${LOGFILE}
return 0
fi
}
checkTTS()
{
if [[ -z ${TTS_INSTANCE_ID} ]];then
echo "Don't Have TTS INSTANCE" 2>&1 | tee ${LOGFILE}
return 0
else
if [[ ${1} == start ]] ; then
/usr/local/spoken/bin/spoken start ${TTS_INSTANCE_ID};
return 0
elif [[ ${1} == stop ]] ; then
/usr/local/spoken/bin/spoken stop ${TTS_INSTANCE_ID};
return 0
else
echo "Wrong function checkTTS parameter transfer"; 2>&1 | tee ${LOGFILE}
exit
fi
fi
}
checkATT_TTS()
{
if [[ -z ${ATT_TTS_INSTANCE_ID} ]];then
echo "Don't Have ATT_TTS INSTANCE running" 2>&1 | tee ${LOGFILE}
return 0
else
if [[ ${1} == start ]] ; then
/usr/local/spoken/bin/spoken start ${ATT_TTS_INSTANCE_ID};
return 0
elif [[ ${1} == stop ]] ; then
/usr/local/spoken/bin/spoken stop ${ATT_TTS_INSTANCE_ID};
return 0
else
echo "Wrong function checkATT_TTS parameter transfer";
exit
fi
fi
}
checkTGWRESTART()
{
if [[ ${1} == idle ]] ; then
echo "Idling the TGW ${TGW_INSTANCE_NAME} to start the TGW restart" 2>&1 | tee ${LOGFILE}
/usr/local/spoken/bin/spoken idle ${TGW_INSTANCE_NAME};
return 0
elif [[ ${1} == stop ]] ; then
/usr/local/spoken/bin/spoken stop ${TGW_INSTANCE_NAME};
return 0
elif [[ ${1} == start ]] ; then
/usr/local/spoken/bin/spoken start ${TGW_INSTANCE_NAME};
return 0
else
echo "Wrong function checkTGWRESTART parameter transfer"; 2>&1 | tee ${LOGFILE}
exit
fi
}
dialogic_CT_INTEL()
{
if [[ ${1} == start ]]; then
/usr/bin/sudo /etc/init.d/ct_intel start;
return 0
elif [[ ${1} == stop ]]; then
/usr/bin/sudo /etc/init.d/ct_intel stop;
return 0
else
echo "Wrong function dialogic_CT_INTEL parameter transfer"; 2>&1 | tee ${LOGFILE}
exit
fi
}
checkDSR()
{
if [[ -z ${DSR_INSTANCE_ID} ]];then
echo "Don't Have DSR INSTANCE" 2>&1 | tee ${LOGFILE}
return 0
else
/usr/local/spoken/bin/spoken restart ${DSR_INSTANCE_ID}; 
return 0
fi
}
checkARR()
{
/usr/local/spoken/bin/spoken restart ${ARR_INSTANCE_ID};
}
checkMSG()
{
/usr/local/spoken/bin/spoken restart ${MSG_INSTANCE_NAME};
}
SPKCONF()
{
if [[ ${1} == stop ]]; then
/usr/bin/sudo /etc/init.d/spkconfmgrd stop;
return 0
else
/usr/bin/sudo /etc/init.d/spkconfmgrd start;
return 0
fi
}
checkTGWMONITOR()
{
if [[ ${1} == stop ]]; then
/usr/local/spoken/bin/spoken stop ${TGW_MON};
return 0
else
/usr/local/spoken/bin/spoken start ${TGW_MON};
return 0
fi
}
checkVARIABLE()
{
echo "1. Host is ${HOSTNAME}" 2>&1 | tee ${LOGFILE}
echo "2. DATACENTER ${ZAB}'s TGW ${TGW_INSTANCE_NAME} is going to restart" 2>&1 | tee ${LOGFILE}
echo "3. ${TGW_INSTANCE_NAME} have ${TGW_ALPHAS}" 2>&1 | tee ${LOGFILE}
echo "4. ${TGW_INSTANCE_NAME} has Instance NO. ${TGW_INSTANCE_NO} going to restart" 2>&1 | tee ${LOGFILE}
echo "5. MESSAGE INSTANCE Name is ${MSG_INSTANCE_NAME}" 2>&1 | tee ${LOGFILE}
echo "6. MESSAGE INSTANCE Alphas ${MSG_ALPHAS}" 2>&1 | tee ${LOGFILE}
echo "7. MESSAGE SERVER's NAME ${MSG_INSTANCE_EX}" 2>&1 | tee ${LOGFILE}
echo "8. TGW MONITOR is ${TGW_MON}" 2>&1 | tee ${LOGFILE}
echo "9. TGW TTS's NAME ${TTS_INSTANCE_ID}" 2>&1 | tee ${LOGFILE}
echo "10. TGW Digital Speech REC. NAME ${DSR_INSTANCE_ID}" 2>&1 | tee ${LOGFILE}
echo "11. TGW Archieve NAME ${ARR_INSTANCE_ID}" 2>&1 | tee ${LOGFILE}
echo "12. DATACENTER is ${ZAB}"  2>&1 | tee ${LOGFILE}
echo "13. TGW ATT_TTS's is ${ATT_TTS_INSTANCE_ID}"  2>&1 | tee ${LOGFILE}
}
#STARTING THE FUNCTION's to RESTART THE TELEPHONY GATEWAY
echo "TGW Variables Instances:" 2>&1 | tee ${LOGFILE}
checkVARIABLE
echo "Adding Host TGW and MSG in Zabbix Maintenance" 2>&1 | tee ${LOGFILE}
ZABBIX_MAIN
echo "Checking the script TGW_RESTART running status" 2>&1 | tee ${LOGFILE}
checkRUNNING_STATUS
echo "Checking ACTIVELINE_COUNT status" 2>&1 | tee ${LOGFILE}
checkACTIVELINE_COUNT
echo "1.SPOKEN Process - Stopping the TGW_MONITOR" 2>&1 | tee ${LOGFILE}
checkTGWMONITOR stop
echo "2.SPOKEN Process - Stopping the TTS" 2>&1 | tee ${LOGFILE}
checkTTS stop
echo "3.SPOKEN Process - Stopping the ATT_TTS" 2>&1 | tee ${LOGFILE}
checkATT_TTS stop
echo "4.SPOKEN Process - Checking SPKCONF stop it" 2>&1 | tee ${LOGFILE}
SPKCONF stop
echo "5.SPOKEN Process - Stopping the TGW" 2>&1 | tee ${LOGFILE}
checkTGWRESTART stop
echo "6.SPOKEN Process - Stopping the CT_INTEL" 2>&1 | tee ${LOGFILE}
dialogic_CT_INTEL stop
sleep 20
echo "7.SPOKEN Process - Starting the CT_INTEL" 2>&1 | tee ${LOGFILE}
dialogic_CT_INTEL start
echo "8.SPOKEN Process - Starting the ATT_TTS" 2>&1 | tee ${LOGFILE}
echo "Sleeping for 2 MINS to start the CT_INTEL Properly"
sleep 120
checkATT_TTS start
echo "9.SPOKEN Process - Starting the TTS" 2>&1 | tee ${LOGFILE}
checkTTS start
echo "10.SPOKEN Process - ReStarting the DSR " 2>&1 | tee ${LOGFILE}
checkDSR
echo "11.SPOKEN Process - ReStarting the ARR " 2>&1 | tee ${LOGFILE}
checkARR
echo "12.SPOKEN Process - ReStarting the MSG " 2>&1 | tee ${LOGFILE}
checkMSG
echo "13.SPOKEN Process - Checking SPKCONF START it" 2>&1 | tee ${LOGFILE}
SPKCONF start
echo "14.SPOKEN Process - Starting the TGW" 2>&1 | tee ${LOGFILE}
sleep 30
checkTGWRESTART start
echo "LAST.SPOKEN Process - Starting the TGW_MONITOR" 2>&1 | tee ${LOGFILE}
checkTGWMONITOR start
rm -f ${LOCKFILE};