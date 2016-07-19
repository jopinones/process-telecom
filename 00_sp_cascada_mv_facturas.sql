USE [Cascadas]
GO
/****** Object:  StoredProcedure [SCL].[usp_scl_cscda_00_factura]    Script Date: 07/12/2016 11:02:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [SCL].[usp_scl_cscda_00_factura]
as
begin
set dateformat dmy
declare @fec_ini datetime, @fec_fin datetime,@fecha datetime
declare @query nvarchar(4000), @sql nvarchar(4000),@fecha2 nvarchar(6)
declare @periodo char(6), @tabla nvarchar(20)
declare @i int, @ano numeric
declare @archivo char(20),@mes numeric
declare @fecha3 datetime

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
select @periodo,@fec_ini,@fec_fin,@fecha

--*******************************************************
select @query=  ' Crear e insertar nueva facturacion '
--*******************************************************
exec usp_Cascadalog @query

IF OBJECT_ID('scl.tmp_fact_scl')IS NOT NULL DROP TABLE scl.tmp_fact_scl

select @query='select b.num_ident, b.nom_cliente, b.nom_apeclien1, b.nom_apeclien2, a.cod_cliente, '+char(13)+char(10)
	      +' cod_categoria, a.cod_tipdocum, a.num_folio, '+char(13)+char(10)
	      +' greatest(trunc(a.fec_emision),to_date(''''01-01-1753'''',''''dd-mm-yyyy'''')) as fec_emision, '+char(13)+char(10) 
	      +' greatest(trunc(a.fec_vencimie),to_date(''''01-01-1753'''',''''dd-mm-yyyy'''')) as fec_vencimie,  '+char(13)+char(10) 
	      +'a.tot_factura as importe '+char(13)+char(10) 
	      +'from fa_histdocu a inner join ge_clientes b on a.cod_cliente=b.cod_cliente '+char(13)+char(10)
	      +'where trunc(a.fec_emision) between to_date(''''' + rtrim(convert(char,@fec_ini,105)) + ''''',''''dd-mm-yyyy'''') '+char(13)+char(10)
	      +'and to_date(''''' + rtrim(convert(char,@fec_fin,105)) + ''''',''''dd-mm-yyyy'''') '+char(13)+char(10)
	      +'and a.cod_tipdocum not in (67,68,25,74) '

select @query='select * into scl.tmp_fact_scl '+char(13)+char(10)
			+'from openquery(BD_SCL,''' + @query + ''')'

exec (@query)

--**************************************************************************************
select @query=  ' Definir Variables y Parametros '
--**************************************************************************************

exec usp_Cascadalog @query

select @i = 0

--**************************************************************************************
select @query=  ' Crear Tabla Facturacion SCL '
--**************************************************************************************

exec usp_Cascadalog @query

select @tabla = 'Fact_'+@periodo

if exists (select * from sysobjects where name=@tabla)
	Begin 
		select @query='Drop Table scl.Fact_'+ @periodo+char(13)+char(10)
		exec(@query)
	End
select @tabla = 'scl.Fact_'+@periodo

	select @query='Create Table scl.Fact_'+ @periodo+char(13)+char(10)
			+' ( origen varchar(3) ,         '+ char(13)+char(10)
			+' emp varchar(3),               ' + char(13)+char(10)
			+' num_ident varchar(20),        ' + char(13)+char(10)
			+' nom_client varchar(95),       ' + char(13)+char(10)
			+' cod_client numeric(18),       ' + char(13)+char(10)
			+' cliente varchar(9),           ' + char(13)+char(10)
			+' cuenta varchar(9),            ' + char(13)+char(10)
			+' cod_tipdoc varchar(3),        ' + char(13)+char(10)
			+' num_folio varchar(18),        ' + char(13)+char(10)
			+' fec_emisio datetime,          ' + char(13)+char(10)
			+' fec_vencim datetime,          ' + char(13)+char(10)
			+' importe numeric(18,0),        ' + char(13)+char(10)
			+' des_catego  varchar(50),      ' + char(13)+char(10)
			+' mes_0 numeric(18)  default 0, ' + char(13)+char(10) 
			+' mes_1 numeric(18)  default 0, ' + char(13)+char(10)
			+' mes_2 numeric(18)  default 0, ' + char(13)+char(10) 
			+' mes_3 numeric(18)  default 0, ' + char(13)+char(10) 
			+' mes_4 numeric(18)  default 0, ' + char(13)+char(10)  
			+' mes_5 numeric(18)  default 0, ' + char(13)+char(10) 
			+' mes_6 numeric(18)  default 0, ' + char(13)+char(10) 
			+' mes_7 numeric(18)  default 0, ' + char(13)+char(10) 
			+' mes_8 numeric(18)  default 0, ' + char(13)+char(10) 
			+' mes_9 numeric(18)  default 0, ' + char(13)+char(10) 
			+' mes_10 numeric(18) default 0, ' + char(13)+char(10) 
			+' mes_11 numeric(18) default 0, ' + char(13)+char(10) 
			+' mes_12 numeric(18) default 0, ' + char(13)+char(10)
			+' llave varchar(30),            ' + char(13)+char(10)
			+' excluir char(1),              ' + char(13)+char(10)
			+' migracion char(1),            ' + char(13)+char(10)
			+' tip_plan varchar(10),         ' + char(13)+char(10)
			+' tip_client varchar(10),       ' + char(13)+char(10)
			+' tip_prod nvarchar(10),        ' + char(13)+char(10)
			+' tramo float,                  ' + char(13)+char(10)
			+' tramo_monto nvarchar(30),     ' + char(13)+char(10)
			+' region nvarchar(2),           ' + char(13)+char(10)
			+' fec_pago datetime,            ' + char(13)+char(10)
			+' num_cuota numeric(8,0),       ' + char(13)+char(10)
			+' sec_cuota numeric(3,0),       ' + char(13)+char(10)
			+' Cant_Abonados numeric(18),    ' + char(13)+char(10)
			+' BAM int,                      ' + char(13)+char(10)
			+' VOZ int,                      ' + char(13)+char(10)
			+' Pack nvarchar(20),            ' + char(13)+char(10)
			+' Estado_Cliente nvarchar(20),  ' + char(13)+char(10)
			+' Portabilidad nvarchar(20),    ' + char(13)+char(10)
			+' Valor nvarchar(20),           ' + char(13)+char(10)
			+' cod_plantarif nvarchar(20),   ' + char(13)+char(10)
			+' Familia_Plan nvarchar(20),    ' + char(13)+char(10)
			+' Carterizado nvarchar(20))     ' + char(13)+char(10)

exec( @query)

--**************************************************************************************
select @query=  ' Homologar Tabla Nueva '
--**************************************************************************************
exec usp_Cascadalog @query

if exists (select * from sysobjects where name='fact_scl')
   drop table scl.fact_scl

select 	origen = 'SCL', 
		emp='SCL', 
		num_ident,
		nom_cliente=rtrim(rtrim(nom_cliente)+' '+rtrim(nom_apeclien1)+' '+rtrim(nom_apeclien2)),
		cod_cliente, 
		des_categoria=coalesce(b.categoria_new,'PERSONAS'),
		cod_tipdocum, 
		num_folio, 
		fec_emision, 
		fec_vencimie, 
		convert(numeric,importe) as importe,
		tipo_plan='NORMAL', 
		tipo_moroso='NORMAL' 
into scl.fact_scl
from scl.tmp_fact_scl a left join [servcluprod1\PRDCLINS01].ctacte.dbo.ge_categorias b 
		on a.cod_categoria=b.cod_categoria 

--**************************************************************************************
select @query=  ' Insertar registros de facturacion '
--**************************************************************************************
exec usp_Cascadalog @query

select @query='insert into scl.Fact_'+@periodo+char(13)+char(10)
		+'(origen, emp, num_ident, nom_client, cod_client, des_catego, cod_tipdoc,'+char(13)+char(10)
		+'num_folio, fec_emisio, fec_vencim, importe, tip_plan, tip_client)'+char(13)+char(10)
		+'select * from scl.fact_scl'

exec(@query)

end