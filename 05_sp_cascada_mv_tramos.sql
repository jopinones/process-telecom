USE [Cascadas]
GO
/****** Object:  StoredProcedure [SCL].[usp_scl_Cscda_05_tramos]    Script Date: 07/12/2016 11:09:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [SCL].[usp_scl_Cscda_05_tramos]
as
begin
set dateformat dmy
declare @fec_ini datetime, @fec_fin datetime,@fecha datetime
declare @query nvarchar(4000), @sql nvarchar(4000),@fecha2 nvarchar(6)
declare @periodo char(6)
declare @i int, @ano numeric
declare @archivo char(20),@mes numeric,@mes2 numeric

--**************************************************************************************
select @sql=  'Aplicar Pagos por Tramo'
--**************************************************************************************
exec usp_Cascadalog @sql

select @i = 0
select @periodo=valor from scl.parametro where parametro='PER_CASCADA'
select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @mes = month(dateadd(mm,-20,@fec_ini))
select @ano = year(dateadd(mm,-20,@fec_ini))
select @periodo,@fec_ini,convert(varchar(10),dateadd(mm,-1,@fec_ini),120),convert(numeric,left(replace(convert(char(10),@fec_ini,120),'-',''),6))

	select @sql=  'Aplicar Tramo 0'
	exec usp_Cascadalog @sql
	select @archivo = right('000'+rtrim(@mes),2)+rtrim(@ano)
	select @query = ' update scl.facturacion_scl_hist set Mes_0 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) <=0 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'') and (mes_0 is null or mes_0 = 0) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 1'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_1 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 1 and 30 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'') and (mes_1 is null or mes_1 = 0 ) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 2'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_2 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 31 and 60 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'') and (mes_2 is null or mes_2 = 0) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 3'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_3 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 61 and 90 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'') and (mes_3 is null or mes_3 = 0) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 4'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_4 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 91 and 120 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'') and (mes_4 is null or mes_4 = 0) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 5'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_5 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 121 and 150 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'')  and (mes_5 is null or mes_5 = 0) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 6'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_6 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 151 and 180 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'')  and (mes_6 is null or mes_6 = 0) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 7'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_7 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 181 and 210 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'') and (mes_7 is null or mes_7 = 0) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 8'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_8 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 211 and 240 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'') and (mes_8 is null or mes_8 = 0) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 9'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_9 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 241 and 270 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'') and (mes_9 is null or mes_9 = 0) option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 10'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_10 = Importe '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 271 and 300 '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'')  and (mes_10 is null or mes_10 = 0) option(maxdop 1)'+char(13)+char(10) 
	exec(@query)

	select @sql=  'Aplicar Tramo 11'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_11 = Importe  '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) between 301 and 330  '+char(13)+char(10)
    +' and rtrim(Origen) in (''SCL'') and (mes_11 is null or mes_11 = 0)  option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	select @sql=  'Aplicar Tramo 12'
	exec usp_Cascadalog @sql
	select @query = ' update scl.facturacion_scl_hist set Mes_12 = Importe  '+char(13)+char(10)
    +' where DATEDIFF(dd,FEC_VENCIM,FEC_PAGO) > 331  '+char(13)+char(10) 
    +' and rtrim(Origen) in (''SCL'') and (mes_12 is null or mes_12 = 0)  option(maxdop 1)'+char(13)+char(10)
	exec(@query)

	--exec usp_Cascadalog 'Marca Riesgos Movil mes actual'
	--declare @qry varchar(8000), @mes1 CHAR(10)
	--select @mes1 = convert(varchar(10),dateadd(mm,-1,@fec_ini),120)
	--set @qry = 'update a set riesgo = riesgo_rut 
	--from scl.facturacion_scl_hist a inner join churn_involuntario_'+left(replace(@mes1,'-',''),6) +' b
	--on a.cod_client = b.cod_cliente
	--where mes_fact = '+ left(replace(convert(char(10),@fec_ini,120),'-',''),6) +'
	--option(maxdop 1)'
	--exec(@qry)
	
	exec usp_Cascadalog 'Marca Riesgos Movil mes actual'
	if exists(select * from sysobjects where name='riesgo_nuevo ') drop table scl.riesgo_nuevo 
	select * into scl.riesgo_nuevo from [servcluprod1\PRDCLINS01].cobex.dbo.cb_nuevo_churn

	declare @qry varchar(8000), @mes1 CHAR(10)
	select @mes1 = convert(varchar(10),dateadd(mm,-1,@fec_ini),120)
	set @qry = 'update a set a.riesgo = b.rg_clientes_cs 
	from scl.facturacion_scl_hist a inner join scl.riesgo_nuevo  b
	on a.cod_client = b.cod_cliente
	where mes_fact = '+ left(replace(convert(char(10),@fec_ini,120),'-',''),6) +'
	option(maxdop 1)'
	exec(@qry)	


	exec usp_Cascadalog 'Marca Vigentes'
	update a set valor ='NO VIGENTE'
	from scl.facturacion_scl_hist a where mes_fact =left(replace(convert(char(10),@fec_ini,120),'-',''),6)

	update a set valor ='VIGENTE'
	from scl.facturacion_scl_hist a inner join scl.vigentes b
	on a.cod_client = b.cod_cliente
	where a.mes_fact = left(replace(convert(char(10),@fec_ini,120),'-',''),6)

	select @sql=  'Fin Aplicar Pagos por Tramo'
	exec usp_Cascadalog @sql
	
	
	select @sql=  'Marca Riesgo reutilizado 4 de super bajo a bajo anterior a agosto 2015 '
	exec usp_Cascadalog @sql
	
	
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201507' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201506' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201505' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201504' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201503' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201502' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201501' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201412' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201411' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201410' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201409' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201408' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201407' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201406' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201405' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201404' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201403' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201402' and riesgo=4
	update scl.facturacion_scl_hist set riesgo=3 where mes_fact='201401' and riesgo=4
	
	
	update scl.facturacion_scl_hist set des_riesgo='ALTO'   where riesgo=0 and mes_fact = left(replace(convert(char(10),@fec_ini,120),'-',''),6)
	update scl.facturacion_scl_hist set des_riesgo='S.ALTO' where riesgo=1 and mes_fact = left(replace(convert(char(10),@fec_ini,120),'-',''),6)
	update scl.facturacion_scl_hist set des_riesgo='MEDIO'  where riesgo=2 and mes_fact = left(replace(convert(char(10),@fec_ini,120),'-',''),6)
	update scl.facturacion_scl_hist set des_riesgo='BAJO'   where riesgo=3 and mes_fact = left(replace(convert(char(10),@fec_ini,120),'-',''),6)
	update scl.facturacion_scl_hist set des_riesgo='S.BAJO' where riesgo=4 and mes_fact = left(replace(convert(char(10),@fec_ini,120),'-',''),6)
	update scl.facturacion_scl_hist set des_riesgo='ND'     where riesgo is null and mes_fact = left(replace(convert(char(10),@fec_ini,120),'-',''),6) 
	
end