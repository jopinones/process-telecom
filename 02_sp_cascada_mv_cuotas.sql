USE [Cascadas]
GO
/****** Object:  StoredProcedure [SCL].[usp_scl_cscda_02_Cuotas]    Script Date: 07/12/2016 11:04:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER procedure [SCL].[usp_scl_cscda_02_Cuotas]
as
begin

set dateformat dmy
declare @fec_ini datetime, @fec_fin datetime,@fecha datetime
declare @query nvarchar(4000), @sql nvarchar(4000),@fecha2 nvarchar(6)
declare @periodo char(6)
declare @i int, @ano numeric
declare @archivo char(20),@mes numeric

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-20,@fec_ini))
select @ano = year(dateadd(mm,-20,@fec_ini))
select @fecha = dateadd(mm,-20,@fec_ini)
select @periodo,@fec_ini,@fec_fin,@fecha

--**************************************************************************************
select @query=  ' Eliminar cuotas canceladas '
--**************************************************************************************
exec usp_Cascadalog @query

delete from scl.co_cancel_Cuota
where clave collate Modern_Spanish_CI_AS in 
(select clave from scl.cta_ctacte_temp)

--**************************************************************************************
select @query=  ' Consolidar Cuotas Pagadas y Pendientes '
--**************************************************************************************
exec usp_Cascadalog @query

insert into scl.co_cancel_Cuota
(Cod_Client,Cod_Tipdoc,Num_folio,Fec_Emisio,Fec_Vencim,
fec_pago,num_cuota,sec_cuota,importe,clave)
select * from scl.cta_ctacte_temp 

delete from scl.co_cancel_Cuota where fec_emisio<=@fec_ini

delete from scl.co_cancel_Cuota where fec_emisio>@fec_fin


--**************************************************************************************
select @query=  ' Eliminar Cuotas ya incorporadas en facturacion '
--**************************************************************************************
exec usp_Cascadalog @query

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @mes = month(dateadd(mm,-15,@fec_ini))
select @ano = year(dateadd(mm,-15,@fec_ini))

truncate table scl.tmp_cuotas
while @i <= 15
begin
	select @archivo = right('000'+rtrim(@mes),2)+rtrim(@ano)
	if exists (select * from sysobjects where name='fact_'+@archivo) 
	begin
		select @query = ' insert into scl.tmp_cuotas  '+char(13)+char(10)
			   +' select rtrim(Cod_Client)+rtrim(Cod_Tipdoc)+  '+char(13)+char(10)
			   +' rtrim(Num_folio)+rtrim(num_cuota)+  '+char(13)+char(10)
			   +' rtrim(sec_cuota) as clave   '+char(13)+char(10)
			   +' from scl.fact_'+@archivo+'  '+char(13)+char(10)
			   +' where num_cuota is not null  '+char(13)+char(10)
		exec(@query)
	end
	select @mes = @mes + 1
	if (@mes = 13)
	begin 
		select @mes = 1
		select @ano = @ano + 1
	end 
	select @i = @i + 1	
end 

delete from scl.co_cancel_Cuota
where clave collate Modern_Spanish_CI_AS in
(select clave from scl.tmp_cuotas)

--**************************************************************************************
select @query=  ' Variables '
--**************************************************************************************
exec usp_Cascadalog @query


select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-20,@fec_ini))
select @ano = year(dateadd(mm,-20,@fec_ini))
select @fecha = dateadd(mm,-20,@fec_ini)


--**************************************************************************************
select @query=  ' Homologar informacion de Cuotas para incorporar en facturacion '
--**************************************************************************************
exec usp_Cascadalog @query

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

	select @query = ' update cuota set Cuota.ORIGEN = fact.ORIGEN,Cuota.EMP =fact.EMP,Cuota.NUM_IDENT =fact.NUM_IDENT, '+char(13)+char(10)
		       +' Cuota.NOM_CLIENT =fact.NOM_CLIENT,Cuota.CLIENTE =fact.CLIENTE,Cuota.CUENTA =fact.CUENTA '+char(13)+char(10)
		       +' ,Cuota.DES_CATEGO = fact.DES_CATEGO'
			   +' ,Cuota.LLAVE =fact.LLAVE, '+char(13)+char(10)
		       +'Cuota.EXCLUIR =fact.EXCLUIR,Cuota.MIGRACION =fact.MIGRACION, '+char(13)+char(10)
		       +'Cuota.TIP_PLAN = fact.TIP_PLAN,Cuota.TIP_CLIENT =fact.TIP_CLIENT, '+char(13)+char(10)
		       +'Cuota.TIP_PROD =fact.TIP_PROD,Cuota.TRAMO=fact.TRAMO '+char(13)+char(10)
		       +'from scl.co_cancel_Cuota cuota, scl.fact_'+@periodo+' fact '+char(13)+char(10)
		       +'where cuota.origen is null and fact.origen in (''SCL'') '+char(13)+char(10)  
		       +'and fact.Cod_Client = cuota.Cod_Client and fact.Cod_Tipdoc = cuota.Cod_Tipdoc  '+char(13)+char(10)
		       +'and fact.Num_folio = cuota.Num_folio '+char(13)+char(10)
	exec(@query)

--**************************************************************************************
select @query=  ' Eliminar Cuotas Nulas '
--**************************************************************************************
exec usp_Cascadalog @query

delete from scl.co_cancel_Cuota where origen is null

--**************************************************************************************
select @query=  ' Eliminar Facturacion Unica de Cuotas '
--**************************************************************************************
select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @mes = month(dateadd(mm,0,@fec_ini))
select @ano = year(dateadd(mm,0,@fec_ini))
	
	select @archivo = right('000'+rtrim(@mes),2)+rtrim(@ano)
	select @query = ' delete from scl.fact_'+@archivo+char(13)+char(10)
		       +' where origen in (''SCL'') and  '+char(13)+char(10)
		       +' rtrim(Cod_Client)+rtrim(Cod_Tipdoc)+  '+char(13)+char(10)
		       +' rtrim(Num_folio) in  '+char(13)+char(10)
		       +' (select rtrim(Cod_Client)+rtrim(Cod_Tipdoc)+  '+char(13)+char(10)
		       +' rtrim(Num_folio) from scl.co_cancel_Cuota  '+char(13)+char(10) 
		       +' where origen is not null)  '+char(13)+char(10)
	exec(@query)

end