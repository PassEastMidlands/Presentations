use master 

-- This Session Trace Flag need to be on so we can user DBCC PAGE later on
DBCC TRACEON (3604);

drop database backups

create database backups

use backups
--File Header
dbcc page (backups,1,0,2) WITH TABLERESULTS
--Page Free Space
dbcc page (backups,1,1,2) WITH TABLERESULTS
--Global Allocation Map
dbcc page (backups,1,2,2) WITH TABLERESULTS
--Shared Global Allocation Map
dbcc page (backups,1,3,2) WITH TABLERESULTS
-- Index Allocation Map
dbcc page (backups,1,4,2) WITH TABLERESULTS
--Differential Changed Map
dbcc page (backups,1,5,2) WITH TABLERESULTS
--Minimal Log Changed Map
dbcc page (backups,1,6,2) WITH TABLERESULTS



--Buffer cache

--Do not use in production!!!
checkpoint
dbcc DROPCLEANBUFFERS 

--Check out empty buffer size

SELECT
	COUNT(*) AS buffer_cache_pages,
	COUNT(*) * 8 / 1024 AS buffer_cache_used_MB
FROM sys.dm_os_buffer_descriptors;
go

-- All page written to buffer cache first:
create table largecache(
col1 char(8000)
)
go
insert into largecache values (replicate('x',8190));
go 8192

SELECT
	COUNT(*) AS buffer_cache_pages,
	COUNT(*) * 8 / 1024 AS buffer_cache_used_MB
FROM sys.dm_os_buffer_descriptors;

--Do not use in production!!!
checkpoint
dbcc DROPCLEANBUFFERS

--All data read through buffer cache
select * from largecache
SELECT
	COUNT(*) AS buffer_cache_pages,
	COUNT(*) * 8 / 1024 AS buffer_cache_used_MB
FROM sys.dm_os_buffer_descriptors;


--Taken from Robert Davis' blog - http://sqlsoldier.net/wp/sqlserver/day11of31daysofdisasterconvertinglsnformats
-- Convert LSN from hexadecimal string to decimal string
Declare @LSN varchar(22),
    @LSN1 varchar(11),
    @LSN2 varchar(10),
    @LSN3 varchar(5),
    @NewLSN varchar(26)

-- LSN to be converted to decimal
select top 1 @lsn=[Current LSN] from fn_dblog(null,null) order by [Current LSN] desc

-- Split LSN into segments at colon
Set @LSN1 = LEFT(@LSN, 8);
Set @LSN2 = SUBSTRING(@LSN, 10, 8);
Set @LSN3 = RIGHT(@LSN, 4);

-- Convert to binary style 1 -> int
Set @LSN1 = CAST(CONVERT(VARBINARY, '0x' +
        RIGHT(REPLICATE('0', 8) + @LSN1, 8), 1) As int);

Set @LSN2 = CAST(CONVERT(VARBINARY, '0x' +
        RIGHT(REPLICATE('0', 8) + @LSN2, 8), 1) As int);

Set @LSN3 = CAST(CONVERT(VARBINARY, '0x' +
        RIGHT(REPLICATE('0', 8) + @LSN3, 8), 1) As int);

-- Add padded 0's to 2nd and 3rd string
Select @LSN,CAST(@LSN1 as varchar(8)) +
    CAST(RIGHT(REPLICATE('0', 10) + @LSN2, 10) as varchar(10)) +
    CAST(RIGHT(REPLICATE('0', 5) + @LSN3, 5) as varchar(5));



Dbcc loginfo()


--first Global Allocation Map at page 2:
dbcc page (backups,1,2,2)

backup database backups to disk='NUL:'
select count(1) from fn_dblog(NULL, NULL)
create table backupdemo (
col1 char(10)
)
insert into backupdemo values ('stuart')


--Get page of table, want PagePID where PageType=1
dbcc ind ('backups','backupdemo',0)
--Row 42 is the diff map status

dbcc page (backups,1,256,2) WITH TABLERESULTS
select count(1) from fn_dblog(NULL,NULL)
select top 1 [Current LSN] from fn_dblog(null,null) order by [Current LSN] desc
backup database backups to Disk='c:\bdemos\full1.bak'
select count(1) from fn_dblog(NULL,NULL)
select * from fn_dblog(NULL,NULL)
00000022:00000104:001e


restore headeronly from Disk='c:\bdemos\full1.bak'
dbcc page (backups,1,256,3) WITH TABLERESULTS

update backupdemo set col1='STUART' where col1='Stuart'
dbcc page (backups,1,256,3) WITH TABLERESULTS

backup database backups to Disk='c:\bdemos\diff1.bak' with differential
restore headeronly from disk ='c:\bdemos\diff1.bak'
dbcc page (backups,1,256,3) WITH TABLERESULTS


--Get number of log records before backup
select count(1) from fn_dblog(NULL,NULL)
--Get log records 
select * from fn_dblog(NULL,NULL)
backup log backups to disk='c:\bdemos\log1.bak'
-- Get starting LSN
restore headeronly from disk='c:\bdemos\log1.bak'
--Number of 'live' log records post backup
select count(1) from fn_dblog(NULL,NULL)

--Get Live Log records
SELECT * FROM
fn_dump_dblog (
NULL, NULL, N'DISK', 1, N'c:\bdemos\log1.bak',
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);








