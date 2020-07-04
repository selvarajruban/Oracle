select name,total_mb/1024 Total_GB,free_MB/1024 Free_GB, ROUND(((total_mb - free_mb)/(total_mb))*100,2) USEDPCT from v$asm_diskgroup 
order by USEDPCT desc;