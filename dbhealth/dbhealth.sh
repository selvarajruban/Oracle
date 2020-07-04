
#!/bin/ksh
# Dated             Version            Author          PR and Descrption
# 20-Aug-2013		1				Database health check mail
#
#


################ Load configuration data . . . . . .  . ###########################

#. $HOME/dbhealth/envsetup.sh

. /home/eeh/ASG_SCRIPTS_DIR/dbhealth/config.cfg

echo "***************************** Testing *************************";
echo $SENDMAIL;
echo $USER;
echo $PWD;
echo $HOSTIP;
echo $PORT;
echo $SID;
echo $FROM;
echo $TO;
echo $CC;
echo $SUBJECT;
echo $DBRHOME;
echo "************************* Test Complete ***************************";

EMAILBODY=$DBRHOME/dbstatusmail.html;


echo "<HTML><HEAD><TITLE>DB Health Report</TITLE><style type="text/css">body.awr {font:bold 8pt Arial,Helvetica,Geneva,sans-serif;color:black; background:White;}
pre.awr  {font:8pt Courier;color:black; background:White;}h1.awr   {font:bold 20pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;border-bottom:1px solid #cccc99;margin-top:0pt; margin-bottom:0pt;padding:0px 0px 0px 0px;}
h2.awr   {font:bold 18pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
h3.awr {font:bold 16pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}li.awr {font: 8pt Arial,Helvetica,Geneva,sans-serif; color:black; background:White;}
th.awrnobg {font:bold 8pt Arial,Helvetica,Geneva,sans-serif; color:black; background:White;padding-left:4px; padding-right:4px;padding-bottom:2px}th.awrbg {font:bold 8pt Arial,Helvetica,Geneva,sans-serif; color:White; background:#0066CC;padding-left:4px; padding-right:4px;padding-bottom:2px}
td.awrnc {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;vertical-align:top;}
td.awrc    {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;}a.awr {font:bold 8pt Arial,Helvetica,sans-serif;color:#663300; vertical-align:top;margin-top:0pt; margin-bottom:0pt;}
</style>
</HEAD>

<BODY class='awr'>
	<H1 class='awr'>
	Database Health Check Report
	</H1>
	<br>
<br><H3 class='awr'>
	Tablespace Report
</H3>
	<P>
<TABLE BORDER=1 WIDTH=800 id ="ts1">
	<TR><TH class='awrbg'>TABLESPACE NAME</TH><TH class='awrbg'>TOTAL SIZE (MB)</TH><TH class='awrbg'>USED (MB)</TH><TH class='awrbg'> FREE (MB)</TH><TH class='awrbg'> USED % </TH></TR>" >$EMAILBODY;


############## Load SQL TNS config parameters  #####################

CONNECTSTRING="$USER/$PWD@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(Host=$HOSTIP)(Port=$PORT))(CONNECT_DATA=(SID=$SID)))"; 
echo $CONNECTSTRING;

############## Check SQL connection #####################
echo "exit" | sqlplus -L "$CONNECTSTRING" | grep Connected > /dev/null 

if [ $? -ne 0 ] 
then
	echo "Failes"
	echo `sqlplus -L "$CONNECTSTRING"` | mailx -s "DB Health Report - ERROR IN CONNECTION" '$TO'
#exit
else
	echo "Connected"
fi

############ Get report details ######################################
get_data()
{
sqlplus -s "$CONNECTSTRING"  <<!
SET NEWPAGE NONE
SET PAGESIZE 0
SET SPACE 0
SET LINESIZE 16000
SET ECHO OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET TERMOUT OFF
SET TRIMOUT ON
SET TRIMSPOOL ON

spool $DBRHOME/tmpsql.values
@$DBRHOME/sql/$1
spool off
exit
!
}

############## 1. Tablespace Report #####################
echo `get_data listtablespace.sql`
while read c1 c2 c3 c4 c5
do
    if [ "$c5" -gt 79 ]
	then
	echo "<tr bgcolor="RED"><td>$c1</td><td>$c2</td><td>$c3</td><td>$c4</td><td>$c5</td></tr>" >>$EMAILBODY;
	elif [ "$c5" -gt 50 -a "$c5" -lt 80 ]
	then
		echo "<tr bgcolor="YELLOW"><td>$c1</td><td>$c2</td><td>$c3</td><td>$c4</td><td>$c5</td></tr>" >>$EMAILBODY;
	else
		echo "<tr><td>$c1</td><td>$c2</td><td>$c3</td><td>$c4</td><td>$c5</td></tr>" >>$EMAILBODY;
fi
	done < $DBRHOME/tmpsql.values

	rm $DBRHOME/tmpsql.values;

echo "</TABLE></P>" >> $EMAILBODY;

############### 2. Temp Tablespace #####################
echo "<br><H3 class="awr">TEMP Tablespace</H3>" >>$EMAILBODY;
echo "<P>
	<TABLE BORDER=1 WIDTH=800 id ="ts1">
	<TR><TH class='awrbg'>TABLESPACE NAME</TH><TH class='awrbg'>TOTAL SIZE (Mb)</TH><TH class='awrbg'>USED (Mb)</TH><TH class='awrbg'>FREE SPACE (Mb) 
</TH></TR>" >> $EMAILBODY;

echo `get_data tempts.sql`
while read c1 c2 c3 c4 
do
    echo "<tr><td>$c1</td><td>$c2</td><td>$c3</td><td>$c4</td></td></tr></table></p>" >>$EMAILBODY;

  done < $DBRHOME/tmpsql.values

  rm $DBRHOME/tmpsql.values;

echo "</TABLE></P>" >> $EMAILBODY;

############ 3. EXTENTS Threshold Check ######################

echo "<br><H3 class="awr">EXTENTS Percentage above 40%</H3>" >>$EMAILBODY;
echo "<P>
	<TABLE BORDER=1 WIDTH=800 id ="ts1">
		<TR><TH class='awrbg'>OWNER</TH><TH class='awrbg'>SEGMENT_NAME</TH><TH class='awrbg'>SEGMENT TYPE</TH><TH class='awrbg'>EXTENTS
		</TH> <TH class='awrbg'>MAX_EXTENTS</TH><TH class='awrbg'>PCT%_USED</TH> </TR>" >> $EMAILBODY;

echo `get_data maxextents.sql`


while read c1 c2 c3 c4 c5 c6
do
if [ "$c6" -gt 80 ];
then
  echo "<tr bgcolor="RED"><td>$c1</td><td>$c2</td><td>$c3</td><td>$c4</td><td>$c5</td><td>$c6</td></tr>" >>$EMAILBODY;
 elif [ "$c6" -gt 60 -a "$c6" -lt 80 ];
  then
      echo "<tr bgcolor="YELLOW"><td>$c1</td><td>$c2</td><td>$c3</td><td>$c4</td><td>$c5</td><td>$c6</td></tr>" >>$EMAILBODY;
  else
     echo "<tr><td>$c1</td><td>$c2</td><td>$c3</td><td>$c4</td><td>$c5</td><td>$c6</td></tr>" >>$EMAILBODY;
  fi
  done < $DBRHOME/tmpsql.values
rm $DBRHOME/tmpsql.values;

echo "</TABLE></P>" >> $EMAILBODY;


############ 4. Disk Group ######################

echo "<br><H3 class="awr">Disk Group Space (ASM)</H3>" >>$EMAILBODY;
echo "<P>
	<TABLE BORDER=1 WIDTH=800 id ="ts1">
		<TR><TH class='awrbg'>NAME</TH><TH class='awrbg'>TOTAL_GB</TH><TH class='awrbg'>FREE_GB</TH><TH class='awrbg'>USEDPCT
		</TH></TR>" >> $EMAILBODY;

echo `get_data diskgroup_space.sql`

while read c1 c2 c3 c4
do
  echo "<tr><td>$c1</td><td>$c2</td><td>$c3</td><td>$c4</td></tr>" >>$EMAILBODY;

done < $DBRHOME/tmpsql.values
rm $DBRHOME/tmpsql.values;

echo "</TABLE></P>" >> $EMAILBODY;


############ 5. Top Waits ######################

echo "<br><H3 class="awr">Top Wait Events</H3>" >>$EMAILBODY;
echo "<P>
	<TABLE BORDER=1 WIDTH=800 id ="ts1">
			<TR><TH class='awrbg'>EVENT NAME</TH><TH class='awrbg'>TOTAL WAITS</TH><TH class='awrbg'>TIME WAITED</TH><TH class='awrbg'>AVG WAIT MS
					</TH></TR>" >> $EMAILBODY;

echo `get_data top_wait.sql`

  echo `cat $DBRHOME/tmpsql.values` >>$EMAILBODY;

  rm $DBRHOME/tmpsql.values;

  echo "</TABLE></P>" >> $EMAILBODY;


############ 6. Resource Limits ######################

echo "<br><H3 class="awr">Resource Limits</H3>" >>$EMAILBODY;
echo "<P>
	<TABLE BORDER=1 WIDTH=800 id ="ts1">
		<TR><TH class='awrbg'>RESOURCE NAME</TH><TH class='awrbg'>CURRENT UTILIZATION</TH><TH class='awrbg'>MAX UTILIZATION</TH><TH class='awrbg'>INITIAL ALLOCATION</TH><TH class='awrbg'>LIMIT VALUE</TH></TR>" >> $EMAILBODY;

echo `get_data resource_limit.sql`

while read c1 c2 c3 c4 c5
do
  echo "<tr><td>$c1</td><td>$c2</td><td>$c3</td><td>$c4</td><td>$c5</td></tr>" >>$EMAILBODY;

done < $DBRHOME/tmpsql.values
rm $DBRHOME/tmpsql.values;

echo "</TABLE></P>" >> $EMAILBODY;

############################### Mail the status html file ##################

echo "</body></html>" >> $EMAILBODY;

#SMAIL="/usr/sbin/sendmail";

(echo "Subject: DB Health Check Report -"$SUBJECT"";echo "From: $FROM"; echo "To: $TO"; echo "MIME-Version: 1.0"; echo "Content-Type: text/html"; echo "Content-Disposition: inline"; cat "$DBRHOME/dbstatusmail.html";)|"$SENDMAIL" "$TO";

############ Send as attachment via mail #################################
# uuencode $EMAILBODY $EMAILBODY | mailx -m -s "DB Health Report" selvaraj.ruban@bt.com
