select '<tr><td>'||a.event||'</td><td>'|| a.total_waits|| '</td><td>'|| a.time_waited || '</td><td>'|| a.average_wait||'</td></tr>'
 From v$system_event a, v$event_name b, v$system_wait_class c
     Where a.event_id=b.event_id
	And b.wait_class#=c.wait_class#
	    And c.wait_class in ('Application','Concurrency','Commit','System I/O','User I/O')
		and a.average_wait > 8
		   order by average_wait desc;
