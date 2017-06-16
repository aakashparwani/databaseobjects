/*
-- Author    : Aakash Parwani
-- Purpose   : Purpose of this stored procedure is to fetch the transactions record from database 
--             and produce a transaction history report for evaluation. Records obtain from this 
--			   procedure will display on client site to provide a business analysis.
*/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'SP_IVR_LastTransactions' AND type = 'P')
	BEGIN
		DECLARE @sql nvarchar(4000)
		SET @sql = 'CREATE PROCEDURE dbo.SP_IVR_LastTransactions AS SELECT 1;'
		EXEC sp_executesql @sql
	END
GO
ALTER PROCEDURE [dbo].[SP_IVR_LastTransactions]          
@NOOFTRANSACTION varchar(8),        
@LASTTRANSACTION varchar(20),        
@FROMDATE datetime,     
@TODATE datetime,  
@BSAcctid int,  
@NOOFDAYS varchar(5),  
@MTCGroupid int         
as
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET nocount ON      
DECLARE @date datetime        
, @b datetime   
, @vFROMDATE datetime  
, @vTODATE datetime
, @LASTTRANIDPPOSTTIME datetime  
, @TOPRecords INT 
, @ArSystemAcctid INT 
, @Arsprocdaystart datetime
, @Arsprocdayend datetime
  
SELECT @ArSystemAcctid = ArSystemAcctid
FROM Dbo.BSegment_Primary BP 
	JOIN Dbo.Org_Balances O  ON ( BP.InstitutionID = O.acctId )
WHERE BP.acctid = @BSAcctid

SELECT @Arsprocdaystart = procdaystart, @Arsprocdayend = procdayend 
FROM Dbo.ArSystemAccounts 
WHERE acctid = @ArSystemAcctid
  
IF EXISTS  
(  
 SELECT 1  
 FROM tempdb.dbo.sysobjects  
 WHERE ID = OBJECT_ID(N'tempdb..#T') AND type = 'U'  
)  
BEGIN  
 DROP TABLE #T    
END  
  
CREATE TABLE #T(  
	[ARTxnBusinessDate] [DATETIME] NULL,
	[TransactionAmount] [MONEY] NULL,
	[TransactionDescription] [VARCHAR](100) NULL,
	[TranID] [DECIMAL](19, 0) NOT NULL,
	[CMTTRANTYPE] [VARCHAR](8) NULL,
	[PostingRef] [VARCHAR](55) NULL,
	[NetFeeAmount] [MONEY] NULL,
	[CardAcceptorNameLocation] [VARCHAR](40) NULL,
	[TxnSource] [VARCHAR](4) NULL,
	[LutDescription] [VARCHAR](100) NULL,
	[DrCrIndicator_MTC] [VARCHAR](5) NULL,
	[TranRef] [DECIMAL](19, 0) NULL,
	[MerchantType] [VARCHAR](4) NULL,
	[TransactionLifeCycleUniqueID] [DECIMAL](19, 0) NULL,
	[MessageTypeIdentifier] [VARCHAR](4) NULL,
	[CardAcceptorIdCode] [VARCHAR](15) NULL,
	[MerchantName] [VARCHAR](25) NULL,
	[MerchantCity] [VARCHAR](12) NULL,
	[MerchantStProvCode] [VARCHAR](3) NULL,
	[ActualTranCode] [VARCHAR](20) NOT NULL,
	[CurrentBalance] [MONEY] NULL
)

IF EXISTS  
(  
 SELECT 1  
 FROM tempdb.dbo.sysobjects  
 WHERE ID = OBJECT_ID(N'tempdb..#T1') AND type = 'U'  
)  
BEGIN  
 DROP TABLE #T1    
END  
  
CREATE TABLE #T1(  
	[SNo] Int NOT NULL Identity(1,1)  Primary Key,
	[ARTxnBusinessDate] [DATETIME] NULL,
	[TransactionAmount] [MONEY] NULL,
	[TransactionDescription] [VARCHAR](100) NULL,
	[TranID] [DECIMAL](19, 0) NOT NULL,
	[CMTTRANTYPE] [VARCHAR](8) NULL,
	[PostingRef] [VARCHAR](55) NULL,
	[NetFeeAmount] [MONEY] NULL,
	[CardAcceptorNameLocation] [VARCHAR](40) NULL,
	[TxnSource] [VARCHAR](4) NULL,
	[LutDescription] [VARCHAR](100) NULL,
	[DrCrIndicator_MTC] [VARCHAR](5) NULL,
	[OldValue] [VARCHAR](32) NULL,
	[NewValue] [VARCHAR](32) NULL,
	[BusinessDay] [DATETIME] NULL,
	[TranRef] [DECIMAL](19, 0) NULL,
	[MerchantType] [VARCHAR](4) NULL,
	[TransactionLifeCycleUniqueID] [DECIMAL](19, 0) NULL,
	[MessageTypeIdentifier] [VARCHAR](4) NULL,
	[CardAcceptorIdCode] [VARCHAR](15) NULL,
	[MerchantName] [VARCHAR](25) NULL,
	[MerchantCity] [VARCHAR](12) NULL,
	[MerchantStProvCode] [VARCHAR](3) NULL,
	[ActualTranCode] [VARCHAR](20) NOT NULL,
	[CurrentBalance] [MONEY] NULL
)

IF EXISTS  
(  
 SELECT 1  
 FROM tempdb.dbo.sysobjects  
 WHERE ID = OBJECT_ID(N'tempdb..#T2') AND type = 'U'  
)  
BEGIN  
 DROP TABLE #T2    
END  
  
CREATE TABLE #T2(  
	[PostTime] [DATETIME] NULL,
	[TransactionAmount] [MONEY] NULL,
	[TransactionDescription] [VARCHAR](100) NULL,
	[TranID] [DECIMAL](19, 0) NOT NULL,
	[CMTTRANTYPE] [VARCHAR](8) NULL,
	[PostingRef] [VARCHAR](55) NULL,
	[NetFeeAmount] [MONEY] NULL,
	[CardAcceptorNameLocation] [VARCHAR](40) NULL,
	[TxnSource] [VARCHAR](4) NULL,
	[LutDescription] [VARCHAR](100) NULL,
	[BeginningBalance] [MONEY] NULL,
	[CurrentBalance] [MONEY] NULL,
	[AmountOfCreditsCTD] [MONEY] NULL,
	[AmountOfDebitsCTD] [MONEY] NULL,
	[servicefeesbnp] [MONEY] NULL,
	[MembershipFeesBNP] [MONEY] NULL,
	[latefeesbnp] [MONEY] NULL,
	[MerchantType] [VARCHAR](4) NULL,
	[DrCrIndicator_MTC] [VARCHAR](5) NULL,
	[TransactionLifeCycleUniqueID] [DECIMAL](19, 0) NULL,
	[MessageTypeIdentifier] [VARCHAR](4) NULL,
	[CardAcceptorIdCode] [VARCHAR](15) NULL,
	[MerchantName] [VARCHAR](25) NULL,
	[MerchantCity] [VARCHAR](12) NULL,
	[MerchantStProvCode] [VARCHAR](3) NULL,
	[ActualTranCode] [VARCHAR](20) NOT NULL,
	[CurrentBalanceTxn] [MONEY] NULL
)
  
--Case When only FromDate is Given  
IF(    ( @FROMDATE!='' OR @FROMDATE IS NOT NULL )
   AND ( @LASTTRANSACTION='' OR @LASTTRANSACTION IS NULL )
   AND ( @NOOFTRANSACTION='' OR @NOOFTRANSACTION IS  NULL )
   AND ( @TODATE='' OR @TODATE IS  NULL )
  )  
BEGIN      
 --PRINT('Case When only FromDate is Given')  
  
	IF((@NOOFTRANSACTION IS NULL) OR (@NOOFTRANSACTION = ''))  
		SET @NOOFTRANSACTION = 5  
	
	IF @FROMDATE = CONVERT(VARCHAR(10), getdate(), 121)  
		set @vFROMDATE=CONVERT(VARCHAR(10), @FROMDATE, 121)  
	else  
		set @vFROMDATE = CONVERT(VARCHAR(10), @FROMDATE, 121) + ' ' + CONVERT(VARCHAR(10),@Arsprocdaystart ,14)
	
	--PRINT @FROMDATE
	--PRINT @NOOFTRANSACTION
	
	SET @TOPRecords = @NOOFTRANSACTION
 
	INSERT INTO #T ( ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance)
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	AND LA.ARTxnBusinessDate >= @vFROMDATE 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC
END     
--CASE when only last transaction is Given  
ELSE IF(	( @LASTTRANSACTION !='' OR @LASTTRANSACTION IS NOT NULL )
		AND ( @TODATE='' OR @TODATE IS  NULL ) 
		AND ( @FROMDATE='' OR  @FROMDATE IS NULL ) 
		AND ( @NOOFTRANSACTION='' OR @NOOFTRANSACTION IS NULL )
	   )    
BEGIN
 --PRINT('CASE when only LASTTRANSACTION is Given ');   
  
	IF( ( @NOOFTRANSACTION IS NULL ) OR ( @NOOFTRANSACTION = '' ) )  
		SET @NOOFTRANSACTION = 5  
  
	SELECT @LASTTRANIDPPOSTTIME = ARTxnBusinessDate FROM LogArTxnAddl WITH (NOLOCK) WHERE Tranid = @LASTTRANSACTION  
	
	--PRINT @LASTTRANSACTION
	--PRINT @LASTTRANIDPPOSTTIME
	
	SET @TOPRecords = @NOOFTRANSACTION

	INSERT INTO #T (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance) 
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	and (    (  LA.ARTxnBusinessDate < @LASTTRANIDPPOSTTIME ) 
		  OR (( LA.ARTxnBusinessDate = @LASTTRANIDPPOSTTIME ) AND C.TranId < @LASTTRANSACTION )
		) 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC
END
--CASE when only To Date is Given  
ELSE IF(	(@TODATE!='' OR @TODATE IS NOT NULL ) 
		AND (@FROMDATE='' OR  @FROMDATE IS NULL ) 
		AND (@LASTTRANSACTION='' OR @LASTTRANSACTION IS NULL ) 
		AND (@NOOFTRANSACTION='' OR @NOOFTRANSACTION IS  NULL )
		AND (@NOOFDAYS='' OR @NOOFDAYS IS NULL )
	   )    
BEGIN      
 --print('we are cheking');    
  
	IF( ( @NOOFTRANSACTION IS NULL ) OR ( @NOOFTRANSACTION = '' ) )  
		SET @NOOFTRANSACTION = 5
	
	SET @vTODATE = CONVERT( VARCHAR(10), @TODATE, 121 )  + ' ' + CONVERT(VARCHAR(10),@Arsprocdayend ,14)  

	--PRINT @NOOFTRANSACTION
	--PRINT @vTODATE

	SET @TOPRecords = @NOOFTRANSACTION
	
	INSERT INTO #T (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance) 
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	AND LA.ARTxnBusinessDate <= @vTODATE 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC
END    
--CASE when From Date and To date are Given  
ELSE IF(	( @TODATE!='' OR @TODATE IS NOT NULL ) 
		AND ( @FROMDATE!='' OR @FROMDATE IS NOT NULL )
		AND ( @NOOFTRANSACTION='' OR @NOOFTRANSACTION IS NULL )
		AND ( @LASTTRANSACTION='' OR @LASTTRANSACTION IS NULL )
		AND ( @NOOFDAYS='' OR @NOOFDAYS IS NULL )
	   )    
BEGIN      
 --print('we are cheking inside this ');    
     
	IF( ( @NOOFTRANSACTION IS NULL ) OR ( @NOOFTRANSACTION = '' ) )  
		SET @NOOFTRANSACTION = 5

	SET @vFROMDATE = CONVERT(varchar(10), @FROMDATE, 121)  + ' ' + CONVERT(VARCHAR(10),@Arsprocdaystart ,14)
	SET @vTODATE = CONVERT(varchar(10), @TODATE, 121)  + ' ' + CONVERT(VARCHAR(10),@Arsprocdayend ,14)  
	
	--PRINT @vFROMDATE
	--PRINT @vTODATE
	
	SET @TOPRecords = @NOOFTRANSACTION
	
	INSERT INTO #T (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance) 
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	AND @vFROMDATE <= LA.ARTxnBusinessDate AND LA.ARTxnBusinessDate <= @vTODATE
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC
END 
--CASE when Only No. of Transaction is Given  
ELSE IF(	( @NOOFTRANSACTION!='' OR @NOOFTRANSACTION IS NOT NULL )  
		AND ( @TODATE='' OR @TODATE IS  NULL ) 
		AND ( @FROMDATE='' OR  @FROMDATE IS NULL ) 
		AND ( @LASTTRANSACTION='' OR @LASTTRANSACTION IS NULL ) 
		AND ( @NOOFDAYS='' OR @NOOFDAYS IS NULL )
	   )    
BEGIN
	--PRINT('we are cheking No. of Transaction only ');   
	
	SET @TOPRecords = @NOOFTRANSACTION
	
	INSERT INTO #T (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance) 
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC
END
--CASE when No. of transaction and Last Transaction are Given  
ELSE IF(	( @NOOFTRANSACTION!='' OR @NOOFTRANSACTION IS NOT NULL )
		AND ( @LASTTRANSACTION!='' OR @LASTTRANSACTION IS NOT NULL )
		AND ( @TODATE='' or @TODATE IS  NULL ) 
		AND ( @FROMDATE='' OR  @FROMDATE IS NULL )
		AND ( @NOOFDAYS='' OR @NOOFDAYS IS NULL )
	   )   
BEGIN    
	--PRINT('we are cheking No. of Transaction and last Transaction ');   
	
	SELECT @LASTTRANIDPPOSTTIME = ARTxnBusinessDate FROM Dbo.LogArTxnAddl WITH (NOLOCK) WHERE Tranid = @LASTTRANSACTION  
	
	--PRINT @LASTTRANSACTION
	--PRINT @LASTTRANIDPPOSTTIME
	
	SET @TOPRecords = @NOOFTRANSACTION

	INSERT INTO #T (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance) 
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID = 51 
	AND T.acctId = @BSAcctid        
	AND (    (  LA.ARTxnBusinessDate < @LASTTRANIDPPOSTTIME ) 
		  OR (( LA.ARTxnBusinessDate = @LASTTRANIDPPOSTTIME ) AND C.TranId < @LASTTRANSACTION )
		) 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC
END
-- CASE when all the field are given(No. of Transaction ,Last Transaction, From Date and to date)  
ELSE IF(	( @NOOFTRANSACTION !='' )
		AND ( @LASTTRANSACTION !='' )
		AND ( @FROMDATE !='' )
		AND ( @TODATE !='' )
	   )    
BEGIN   
	-- PRINT('we are cheking All Field ');   
  
	SELECT @LASTTRANIDPPOSTTIME = ARTxnBusinessDate FROM Dbo.LogArTxnAddl WITH (NOLOCK) WHERE Tranid = @LASTTRANSACTION  
	
	--PRINT @LASTTRANSACTION
	--PRINT @LASTTRANIDPPOSTTIME
	
	SET @vFROMDATE = CONVERT(varchar(10), @FROMDATE, 121)  + ' ' + CONVERT(VARCHAR(10),@Arsprocdaystart ,14)  
	SET @vTODATE = CONVERT(varchar(10), @TODATE, 121)  + ' ' + CONVERT(VARCHAR(10),@Arsprocdayend ,14)  
	
	--PRINT @vFROMDATE
	--PRINT @vTODATE
	
	SET @TOPRecords = @NOOFTRANSACTION
	
	INSERT INTO #T (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance) 
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid 
	AND @vFROMDATE <= LA.ARTxnBusinessDate AND LA.ARTxnBusinessDate <= @vTODATE
	and (    (  LA.ARTxnBusinessDate < @LASTTRANIDPPOSTTIME ) 
		  OR (( LA.ARTxnBusinessDate = @LASTTRANIDPPOSTTIME ) AND C.TranId < @LASTTRANSACTION )
		) 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC
END
--CASE when NOOFTRANSACTION field and TODATE are given  
ELSE IF(	( @NOOFTRANSACTION != '' OR @NOOFTRANSACTION IS NOT NULL ) 
		AND ( @TODATE != '' OR @TODATE IS NOT NULL )
		AND ( @LASTTRANSACTION = '' OR @LASTTRANSACTION IS NULL )
		AND ( @FROMDATE = '' OR @FROMDATE IS NULL )
		AND ( @NOOFDAYS = '' OR @NOOFDAYS IS NULL )
	   )
BEGIN
	-- PRINT('CASE when NOOFTRANSACTION field and TODATE are given')  
  
	SET @vTODATE = CONVERT( VARCHAR(10), @TODATE, 121 )  + ' ' + CONVERT(VARCHAR(10),@Arsprocdayend ,14)

	--PRINT @NOOFTRANSACTION
	--PRINT @vTODATE

	SET @TOPRecords = @NOOFTRANSACTION
	
	INSERT INTO #T (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance) 
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	AND LA.ARTxnBusinessDate <= @vTODATE 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC  
END 
-- CASE when NOOFTRANSACTION field and FromDate are given   
ELSE IF(	( @NOOFTRANSACTION != '' OR @NOOFTRANSACTION IS NOT NULL ) 
		AND ( @FROMDATE != '' OR @FROMDATE IS NOT NULL )
		AND ( @TODATE = '' OR @TODATE IS NULL )
		AND ( @LASTTRANSACTION = ''OR @LASTTRANSACTION IS NULL )
		AND ( @NOOFDAYS = '' OR @NOOFDAYS IS NULL )
	   )    
BEGIN
	-- PRINT('CASE when NOOFTRANSACTION field and FromDate are given')
	
	SET @vFROMDATE = CONVERT(VARCHAR(10), @FROMDATE, 121) + ' ' + CONVERT(VARCHAR(10),@Arsprocdaystart ,14)
	
	--PRINT @FROMDATE
	--PRINT @NOOFTRANSACTION
	
	SET @TOPRecords = @NOOFTRANSACTION
 
	INSERT INTO #T ( ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance)
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	AND LA.ARTxnBusinessDate >= @vFROMDATE 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC  
END   
-- CASE when NOOFTRANSACTION field, TODATE and FromDate are given   
ELSE IF(	(@NOOFTRANSACTION != '' OR @NOOFTRANSACTION IS NOT NULL )
		AND (@TODATE != '' OR @TODATE IS NOT NULL )
		AND (@LASTTRANSACTION = '' OR @LASTTRANSACTION IS NULL )
		AND (@FROMDATE != '' OR @FROMDATE IS NOT NULL )
	   )  
BEGIN
	-- PRINT('CASE when NOOFTRANSACTION field, TODATE and FromDate are given ')  
  
	SET @vFROMDATE = CONVERT(varchar(10), @FROMDATE, 121)  + ' ' + CONVERT(VARCHAR(10),@Arsprocdaystart ,14)
	SET @vTODATE = CONVERT(varchar(10), @TODATE, 121)  + ' ' + CONVERT(VARCHAR(10),@Arsprocdayend ,14) 
	
	--PRINT @vFROMDATE
	--PRINT @vTODATE
	
	SET @TOPRecords = @NOOFTRANSACTION
	
	INSERT INTO #T (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance) 
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	AND @vFROMDATE <= LA.ARTxnBusinessDate AND LA.ARTxnBusinessDate <= @vTODATE
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC   
END
-- when number of days is given  
ELSE IF(	( @NOOFDAYS != '' OR @NOOFDAYS IS NOT NULL )
		AND ( @TODATE = '' OR @TODATE IS  NULL )
		AND ( @NOOFTRANSACTION = '' OR @NOOFTRANSACTION IS  NULL )
		AND ( @LASTTRANSACTION = '' OR @LASTTRANSACTION IS NULL )
		AND ( @FROMDATE = '' OR @FROMDATE IS  NULL )
	   )  
BEGIN
	-- PRINT('when number of days is given')  

	SET @NOOFDAYS = - CAST(@NOOFdAYS AS INT)  
	SELECT @b = DATEADD(DD, CAST(@NOOFdAYS AS INT), @Arsprocdaystart)  
	SET @vFROMDATE = CONVERT(VARCHAR(10), @b, 121) + ' ' + CONVERT(VARCHAR(10),@Arsprocdaystart ,14) 
	
	--PRINT @vFROMDATE
	
	INSERT INTO #T ( ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance)
	SELECT
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					  ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	AND LA.ARTxnBusinessDate >= @vFROMDATE 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        

END
-- CASE when No of days and  TODATE  are given  
ELSE IF(	( @NOOFDAYS != '' OR @NOOFDAYS IS NOT NULL )   
		AND ( @TODATE!= '' OR @TODATE IS NOT NULL )   
		AND ( @NOOFTRANSACTION = '' OR @NOOFTRANSACTION IS  NULL )    
		AND ( @LASTTRANSACTION = '' OR @LASTTRANSACTION IS NULL )  
		AND ( @FROMDATE = '' OR @FROMDATE IS  NULL )
	   )  
BEGIN
	-- PRINT('CASE when No of days and  TODATE  are given')  

	
	SET @NOOFDAYS = - CAST(@NOOFdAYS AS INT)  
	SELECT @b = DATEADD(DD, CAST(@NOOFdAYS AS INT), @TODATE)  
	SET @vFROMDATE = CONVERT(VARCHAR(10), @b, 121) + ' ' + CONVERT(VARCHAR(10),@Arsprocdaystart ,14)
	SET @vTODATE = CONVERT(VARCHAR(10), @vTODATE, 121) + ' ' + CONVERT(VARCHAR(10), @Arsprocdayend ,14)
	
	IF( ( @NOOFTRANSACTION IS NULL ) OR ( @NOOFTRANSACTION = '' ) )  
		SET @NOOFTRANSACTION = 5
	
	--PRINT @NOOFTRANSACTION
	--PRINT @vTODATE

	SET @TOPRecords = @NOOFTRANSACTION
	
	INSERT INTO #T (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance) 
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	 Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	AND LA.ARTxnBusinessDate <= @vTODATE 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC 
END
-- CASE when No of days and   No. of Transaction is Given  
ELSE IF(	(@NOOFTRANSACTION!='' or @NOOFTRANSACTION is not null )
		and (@NOOFDAYS != '' or @NOOFDAYS is not null)
		and (@TODATE='' or @TODATE is  null)
		and (@LASTTRANSACTION=''or @LASTTRANSACTION is null )
		and (@FROMDATE ='' or @FROMDATE is  null)
	   )
BEGIN
	-- PRINT('we are cheking No of days and   No. of Transaction ')  
	
	SET @NOOFDAYS = - CAST(@NOOFdAYS AS INT)  
	SELECT @b = DATEADD(DD, CAST(@NOOFdAYS AS INT), @Arsprocdaystart)  
	SET @vFROMDATE = CONVERT(VARCHAR(10), @b, 121) + ' ' + CONVERT(VARCHAR(10),@Arsprocdaystart ,14) 
	
	--PRINT @vFROMDATE 
  
	SET @TOPRecords = @NOOFTRANSACTION
 
	INSERT INTO #T ( ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance)
	SELECT TOP (@TOPRecords)
			LA.ARTxnBusinessDate,C.TransactionAmount,C.TransactionDescription,C.tranid,C.cmttrantype,C.PostingRef,
			C.NetFeeAmount,S.CardAcceptorNameLocation, C.TxnSource,TC.lutdescription,MC.DrCrIndicator_MTC ,
			C.tranRef,C.MerchantType,C.TransactionLifeCycleUniqueID,C.MessageTypeIdentifier,AP.CardAcceptorIdCode,
			S.MerchantName,C.MerchantCity,C.MerchantStProvCode,MC.ActualTranCode,CBL.CurrentBalance 
	FROM	Dbo.CCard_Primary C WITH (nolock)
		JOIN Dbo.TranCodeLookup TC WITH (nolock) ON (C.TxnCode_Internal = TC.lutcode AND  TC.LUTid = 'TranCode') 
		LEFT JOIN Dbo.Auth_Primary AP WITH (nolock) ON (C.AuthTranId = AP.TranId)
		JOIN Dbo.CCard_Secondary S WITH (nolock) ON (C.TranId = S.TranId)
		JOIN Dbo.trans_in_acct T WITH (nolock) ON (C.TranId=T.tran_id_index )
		JOIN Dbo.Monetarytxncontrol MC WITH (nolock) ON (/*C.CMTTRANTYPE = MC.LogicModule AND*/ C.TxnCode_Internal = MC.TransactionCode)
		JOIN Dbo.LogArTxnAddl LA WITH (nolock) ON (C.TranID = LA.TranID)
		JOIN Dbo.CBLog CBL WITH (nolock) ON (C.TranID = CBL.TranID)  
	WHERE 
	C.CMTTRANTYPE IN ( '02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'
					  ,'21','22','23','26','30','31','35','36','37','38','48','49','40','41','42','43','44','45','148','149'
					 ) 
	AND T.ATID=51 
	AND T.acctId = @BSAcctid        
	AND LA.ARTxnBusinessDate >= @vFROMDATE 
	AND MC.Groupid = @MTCGroupid 
	AND TC.LutRelation = @MTCGroupid        
	ORDER BY LA.ARTxnBusinessDate DESC, C.TranId DESC
END

INSERT INTO #T1 (ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,OldValue,NewValue,BusinessDay,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance)
SELECT ARTxnBusinessDate,TransactionAmount,TransactionDescription,TranID,CMTTRANTYPE,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,LutDescription,DrCrIndicator_MTC,OldValue,NewValue,BusinessDay,TranRef,MerchantType,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,Tmp.CurrentBalance  
FROM #T Tmp LEFT OUTER JOIN Dbo.CurrentBalanceAudit cb WITH (nolock)  
ON 
(	(cb.dename = 111 AND cb.aid=@BSAcctid AND cb.atid=51) 
	AND (  Tmp.tranid=cb.tid 
		OR	( Tmp.ARTxnBusinessDate = cb.businessday AND Tmp.TranRef = cb.tid )  
		OR	( Tmp.ARTxnBusinessDate = cb.businessday AND cb.tid = 0 )
		)
)  


INSERT INTO #T2(PostTime,TransactionAmount,TransactionDescription,tranid,cmttrantype,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,lutdescription,BeginningBalance,CurrentBalance,MerchantType,DrCrIndicator_MTC,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalanceTxn)   
SELECT ARTxnBusinessDate,TransactionAmount,TransactionDescription,tranid,cmttrantype,PostingRef,NetFeeAmount,CardAcceptorNameLocation,TxnSource,lutdescription,oldvalue,newvalue,MerchantType,DrCrIndicator_MTC,TransactionLifeCycleUniqueID,MessageTypeIdentifier,CardAcceptorIdCode,MerchantName,MerchantCity,MerchantStProvCode,ActualTranCode,CurrentBalance
FROM #T1 


UPDATE #T2 
	SET AmountOfCreditsCTD = ( SELECT SUM(transactionamount) FROM #T1 WHERE DrCrIndicator_MTC = -1 AND CMTTRANTYPE NOT IN ('03','05','07','09','11','13','15','17','19') )  
	, AmountOfDebitsCTD = ( SELECT SUM(transactionamount) FROM #T1 WHERE DrCrIndicator_MTC=1 AND cmttrantype NOT IN ('02','04','06','08','10','12','14','16','18') )  

UPDATE #T2 SET latefeesbnp = ( SELECT SUM(transactionamount) FROM #T1 WHERE CMTTRANTYPE IN ('03','05','07','09','11','13','15','17','19') )  
	, MembershipFeesBNP = ( SELECT SUM(transactionamount) FROM #T1 WHERE CMTTRANTYPE IN ('02','04','06','08','10','12','14','16','18') )

UPDATE #T2 SET servicefeesbnp = ( SELECT TOP 1 ISNULL(MembershipFeesBNP,0.00) - ISNULL(latefeesbnp,0.00) FROM #T1 )  
	, CurrentBalance = ( SELECT TOP 1 NewValue FROM #T1 WHERE BusinessDay in (SELECT TOP 1 MAX(BusinessDay) FROM #T1 ) )  
	, BeginningBalance = ( SELECT TOP 1 OldValue FROM #T1 WHERE BusinessDay in (SELECT TOP 1 MIN(BusinessDay) FROM #T1 ) )

SELECT * FROM #T2 ORDER BY PostTime DESC, TranID DESC


/*
EXEC SP_IVR_LastTransactions NULL,NULL,NULL,NULL,52066,600,13
EXEC SP_IVR_LastTransactions 10,NULL,NULL,NULL,52066,NULL,13
EXEC SP_IVR_LastTransactions NULL,329426240,NULL,NULL,52066,NULL,13
EXEC SP_IVR_LastTransactions NULL,329426240,NULL,NULL,52066,NULL,13
*/
GO
