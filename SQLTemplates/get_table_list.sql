SELECT 
	* 
FROM 
	sqlite_master 
WHERE 
	type = 'table'
	and 
	tbl_name <> 'sqlite_sequence'