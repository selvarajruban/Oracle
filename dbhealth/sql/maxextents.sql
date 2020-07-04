SELECT * FROM (
SELECT OWNER,SEGMENT_NAME,SEGMENT_TYPE,EXTENTS,MAX_EXTENTS, 
     ROUND ((EXTENTS / MAX_EXTENTS) * 100, 2)  "MAX_EXT_PCT"
	  FROM DBA_SEGMENTS
	      WHERE OWNER NOT IN ('SYS', 'SYSTEM','OUTLN') AND MAX_EXTENTS <> 0
		  ORDER BY 6 DESC) A
		  WHERE A.MAX_EXT_PCT  > 40;
