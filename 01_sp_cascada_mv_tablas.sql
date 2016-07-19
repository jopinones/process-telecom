USE [Cascadas]
GO
/****** Object:  StoredProcedure [SCL].[usp_scl_cscda_01_tablas]    Script Date: 07/12/2016 11:03:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [SCL].[usp_scl_cscda_01_tablas]
as
begin

set dateformat dmy
declare @fec_ini datetime, @fec_fin datetime,@fecha datetime
declare @query nvarchar(4000), @sql nvarchar(4000),@fecha2 nvarchar(6)
declare @periodo char(6)
declare @i int, @ano numeric
declare @archivo char(20),@mes numeric
declare @fecha3 datetime

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-20,@fec_ini))
select @ano = year(dateadd(mm,-20,@fec_ini))
select @fecha = dateadd(mm,-20,@fec_ini)
select @fecha3 =dateadd(ss,-1,dateadd(mm,1,@fecha))
select @periodo,@fec_ini,@fec_fin,@fecha,@fecha3

--*******************************************************
select @query=  ' Carga Cb_Bam '
--*******************************************************
exec usp_Cascadalog @query
--MODIFICACION HECHA EL 21/02/204 por rpina
drop table scl.cb_bam
select cod_cliente,num_abonado
into scl.cb_bam
from procesos..ga_abocel a
inner join [SERVCLUPROD1\PRDCLINS01].cobex.dbo.bm_plan_bam b
on a.cod_plantarif collate Modern_Spanish_CI_AS = b.cod_plantarif
group by cod_cliente,num_abonado

/*select @query='select cod_cliente, num_abonado, cod_situacion, '+char(13)+char(10)
+' a.fec_alta, a.fec_baja, max(c.des_articulo) as equipo '+char(13)+char(10) 
+' from (ga_abocel a inner join ga_equipaboser b on a.num_abonado=b.num_abonado '+char(13)+char(10)
+' and a.num_imei=b.num_serie and a.fec_alta=b.fec_alta )  '+char(13)+char(10)
+' inner join al_articulos c on b.cod_articulo=c.cod_articulo  '+char(13)+char(10)
+' where (des_articulo like ''''%HUAWEI%''''  '+char(13)+char(10)
+' or (des_articulo like ''''%TARJETA%''''   '+char(13)+char(10)
+' and des_articulo like ''''%PCMCIA%'''')  '+char(13)+char(10)
+' or des_articulo like ''''%MODEM%''''  '+char(13)+char(10)
+' or des_articulo like ''''%MODEN%'''')  '+char(13)+char(10)
+' and des_articulo like ''''%3G%''''  '+char(13)+char(10)
+' group by a.cod_cliente, a.num_abonado,   '+char(13)+char(10)
+' a.cod_situacion, a.fec_alta, a.fec_baja  '

select @sql='truncate table scl.cb_bam insert into scl.cb_bam select * '+char(13)+char(10)
		   +'from openquery(BD_IVRIN,''' + @query + ''')'

exec(@sql)
*/

--**************************************************************************************
select @query=  ' Definir Variables y Parametros '
--**************************************************************************************
exec usp_Cascadalog @query

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-20,@fec_ini))
select @ano = year(dateadd(mm,-20,@fec_ini))
select @fecha = dateadd(mm,-20,@fec_ini)
select @fecha3 =dateadd(ss,-1,dateadd(mm,1,@fecha))

--**************************************************************************************
select @query=  ' Tabla de Pagos '
--**************************************************************************************
exec usp_Cascadalog @query


select @query=' select cod_cliente,cod_tipdocum, num_folio, '+char(13)
		   +' greatest(trunc(fec_efectividad),to_date(''''01-01-1753'''',''''dd-mm-yyyy'''')) as fec_efectividad, '+char(13)
		   +' greatest(trunc(fec_vencimie),to_date(''''01-01-1753'''',''''dd-mm-yyyy''''))  as fec_vencimie, '+char(13)
		   +' greatest(trunc(fec_pago),to_date(''''01-01-1753'''',''''dd-mm-yyyy'''')) as fec_pago, '+char(13)
		   +' num_cuota,sec_cuota,importe_Debe,importe_haber from co_cancelados '+char(13)
		   +' where greatest(trunc(fec_pago),to_date(''''01-01-1753'''',''''dd-mm-yyyy'''')) '+char(13)
		   +' between  to_date(''''' + rtrim(convert(char,@fec_ini,105)) + ''''',''''dd-mm-yyyy'''') '+char(13)
	       +' and to_date(''''' + rtrim(convert(char,@fec_fin,105)) + ''''',''''dd-mm-yyyy'''') '+char(13)
	       +' and cod_tipdocum not in (67,68,25,74) '+char(13)
		   +' and fec_efectividad>=sysdate-720'

select @sql=' truncate table scl.tmp_co_cancel insert into scl.tmp_co_cancel select * '+char(13)+char(10)
		   +' from openquery(BD_SCL,''' + @query + ''') '

exec(@sql)

--**************************************************************************************
select @query=  ' Insertar Registros en Tabla Final '
--**************************************************************************************
exec usp_Cascadalog @query

select @sql='  truncate table scl.co_cancel insert into scl.co_cancel select cod_cliente, '+char(13)+char(10)
		   +' cod_tipdocum, num_folio,fec_efectividad=max(fec_efectividad),fec_vencimie, '+char(13)+char(10)
		   +' fec_pago = max(fec_pago),num_cuota,sec_cuota,sum(importe_Debe) '+char(13)+char(10)
		   +' importe_Debe,sum(importe_haber) importe_haber '+char(13)+char(10)
		   +' from scl.tmp_co_cancel group by cod_cliente,cod_tipdocum, '+char(13)+char(10) 
		   +' num_folio,fec_vencimie, '+char(13)+char(10)
		   +' num_cuota,sec_cuota '+char(13)+char(10)
exec(@sql)

--**************************************************************************************
select @query=  ' Cuotas Canceladas '
--**************************************************************************************
exec usp_Cascadalog @query

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))

select @sql='  truncate table cascadas.scl.co_cancel_Cuota  '+char(13)+char(10)
		   +' insert into cascadas.scl.co_cancel_Cuota  '+char(13)+char(10)
		   +' (Cod_Client,Cod_Tipdoc,Num_folio,Fec_Emisio,Fec_Vencim,  '+char(13)+char(10)
		   +' fec_pago,num_cuota,sec_cuota,importe,clave)  '+char(13)+char(10)
		   +' select Cod_Cliente as Cod_Client,  '+char(13)+char(10)
		   +' Cod_Tipdocum as Cod_Tipdoc,  '+char(13)+char(10)
		   +' Num_folio,fec_efectividad as Fec_Emisio,  '+char(13)+char(10)
		   +' fec_vencimie as Fec_Vencim,  '+char(13)+char(10)
		   +' null,num_cuota,sec_cuota,importe_haber as importe,  '+char(13)+char(10)
		   +' rtrim(Cod_Cliente)+rtrim(Cod_Tipdocum)  '+char(13)+char(10)
		   +' +rtrim(Num_folio)+rtrim(num_cuota)  '+char(13)+char(10)
		   +' +rtrim(sec_cuota) as clave  '+char(13)+char(10)
		   +' from cascadas.scl.co_cancel where num_cuota > 1  '+char(13)+char(10)
		   +' and cod_tipdocum not in (67,68,25,74)  '+char(13)+char(10)
		   +' and fec_efectividad  >= '''+rtrim(convert(char,@fec_ini,105))+''''+char(13)+char(10)
exec(@sql)

--**************************************************************************************
select @query=  ' Definir Variables y Parametros '
--**************************************************************************************
exec usp_Cascadalog @query

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-20,@fec_ini))
select @ano = year(dateadd(mm,-20,@fec_ini))
select @fecha = dateadd(mm,-20,@fec_ini)

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')

	select @fecha = dateadd(mm,-20,@fec_ini)

--**************************************************************************************
select @query=  ' Cuenta Corriente  '
--**************************************************************************************
exec usp_Cascadalog @query

	select @query = ' truncate table scl.cta_ctacte_temp '+char(13)+char(10)
		       +' insert into scl.cta_ctacte_temp '+char(13)+char(10)
		       +' (Cod_Client,Cod_Tipdoc,Num_folio,Fec_Emisio,Fec_Vencim, '+char(13)+char(10)
		       +' fec_pago,num_cuota,sec_cuota,importe,clave) '+char(13)+char(10)
		       +' select Cod_Cliente as Cod_Client, '+char(13)+char(10)
		       +' Cod_Tipdocum as Cod_Tipdoc, '+char(13)+char(10)
		       +' Num_folio,Fec_Emision as Fec_Emisio, '+char(13)+char(10)
		       +' fec_vencimie as Fec_Vencim,null as Fec_Pago, '+char(13)+char(10)
		       +' num_cuota,sec_cuota,importe, '+char(13)+char(10)
		       +' rtrim(Cod_Cliente)+rtrim(Cod_Tipdocum) '+char(13)+char(10)
		       +' +rtrim(Num_folio)+rtrim(num_cuota) '+char(13)+char(10)
		       +' +rtrim(sec_cuota) as clave '+char(13)+char(10)
		       +' from [servcluprod1\PRDCLINS01].ctacte_consultas.dbo.cta_ctacte_'+@periodo+' '+char(13)+char(10)
		       +' where origen in (''SCL'') and num_cuota > 1 '+char(13)+char(10)
		       +' and fec_emision >= '''+rtrim(convert(char,@fecha,105))+''' and cod_tipdocum not in (67,68,25,74) '+char(13)+char(10)
	exec(@query)

--**************************************************************************************
select @query=  ' Definir Variables y Parametros '
--**************************************************************************************
exec usp_Cascadalog @query

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-20,@fec_ini))
select @ano = year(dateadd(mm,-20,@fec_ini))
select @fecha = dateadd(mm,-20,@fec_ini)


--*******************************************************
select @query=  ' Carga Migrados '
--*******************************************************
exec usp_Cascadalog @query


truncate table scl.migrados_cod
select @query='insert into scl.migrados_cod (cod_cliente) select cod_cliente '+char(13)+char(10)
	      +'from [servcluprod1\PRDCLINS01].ctacte.dbo.migrados_cod '
	      +'group by cod_cliente ' 
exec(@query)

/*select @query='insert into scl.migrados_cod (cod_cliente) select cod_cliente '+char(13)+char(10)
	      +'from movil.dbo.migrados_cod '+char(13)+char(10)
	      +'group by cod_cliente ' 
exec(@query)*/

--*******************************************************
select @query=  ' Carga CtaCte '
--*******************************************************
exec usp_Cascadalog @query

truncate table scl.ctacte
select @query= 'insert into scl.ctacte '+char(13)+char(10)
		+' select origen, emp, cod_cliente, cod_tipdocum, num_folio, '+char(13)+char(10)
		+' fec_emision, fec_vencimie,importe '+char(13)+char(10)
		+' from [servcluprod1\PRDCLINS01].ctacte_consultas.dbo.cta_ctacte_'+rtrim(@periodo)+char(13)+char(10)
exec (@query)

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'

select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-20,@fec_ini))
select @ano = year(dateadd(mm,-20,@fec_ini))
select @fecha = dateadd(mm,-20,@fec_ini)

--**************************************************************************************
select @query=  ' Cargar Tabla Repactaciones '
--**************************************************************************************
exec usp_Cascadalog @query

truncate table scl.tmp_repac
insert into scl.tmp_repac
select cod_cliente as cod_client, cod_tipfac as Cod_Tipdoc,
num_folio, sum(imp_repacta) as imp_rep
from [servcluprod1\PRDCLINS01].ctacte_consultas.dbo.cta_repacta_movil_folios_1
group by cod_cliente, cod_tipfac, num_folio


--**************************************************************************************
select @query=  ' Cargar Tabla Abonados '
--**************************************************************************************
exec usp_Cascadalog @query

select @i = 0

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'
select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @fecha2 = rtrim(year(@fec_ini)*100+month(@fec_ini))

	select @query=' insert into scl.Abonados '+char(13)+char(10)
			+' select Periodo = '''+@fecha2+''',Cod_Cliente,count(*) as Cant_Abonados  '+char(13)+char(10)
			+' from procesos.dbo.ga_abocel '+char(13)+char(10)
			+' where  rtrim(convert(char,fec_alta,105)) <= '''+rtrim(convert(char,@fec_fin,105))+'''  '+char(13)+char(10)
			+' and  (rtrim(convert(char,fec_baja,105)) > '''+rtrim(convert(char,@fec_fin,105))+''' '+char(13)+char(10)
			+' or  rtrim(convert(char,fec_baja,105)) is null )'+char(13)+char(10)
			+' Group by Cod_Cliente '+char(13)+char(10)
	exec(@query)

--**************************************************************************************
select @query=  ' Cargar Cartera Especial '
--**************************************************************************************
exec usp_Cascadalog @query

drop table scl.cta_cespecial

select * into scl.cta_cespecial
from [servcluprod1\PRDCLINS01].cespecial.dbo.cta_cespecial

drop table scl.cta_origen 

select * into scl.cta_origen 
from [servcluprod1\PRDCLINS01].cespecial.dbo.cta_origen 

drop table scl.cta_entidad

select * into scl.cta_entidad
from [servcluprod1\PRDCLINS01].cespecial.dbo.cta_entidad

--**************************************************************************************
select @query=  ' Cargar Hibridos '
--**************************************************************************************
exec usp_Cascadalog @query

drop table scl.cta_hibridos
select * into scl.cta_hibridos
from [servcluprod1\PRDCLINS01].ctacte.dbo.cta_hibridos

--**************************************************************************************
select @query=  ' Planes Movil'
--**************************************************************************************
exec usp_Cascadalog @query

drop table scl.Planes_Movil
select * into scl.Planes_Movil
from [servcluprod1\PRDCLINS01].tablas.dbo.Planes_Movil

drop table scl.vigentes
select cod_cliente into scl.vigentes 
from [servcluprod1\PRDCLINS01].tablas.dbo.ga_abocel where cod_situacion not in ('BAA','BTP')
group by cod_cliente

----**************************************************************************************
--select @query=  ' Rut Carterizados'
----**************************************************************************************
--exec usp_Cascadalog @query

--drop table scl.tmp_rut_negocios_carterizados
--select * into scl.tmp_rut_negocios_carterizados
--from [servcluprod1\PRDCLINS01].ctacte.dbo.tmp_rut_negocios_carterizados

end