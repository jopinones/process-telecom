USE [Cascadas]
GO
/****** Object:  StoredProcedure [SCL].[usp_scl_Cscda_04_pagos]    Script Date: 07/12/2016 11:07:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  procedure [SCL].[usp_scl_Cscda_04_pagos]
as
begin
set dateformat dmy
declare @fec_ini datetime, @fec_fin datetime,@fecha datetime
declare @query nvarchar(4000), @sql nvarchar(4000),@fecha2 nvarchar(6)
declare @periodo char(6)
declare @i int, @ano numeric
declare @archivo char(20),@mes numeric,@mes2 numeric

select @periodo=valor from scl.parametro where parametro='PER_CASCADA'
select @i = 1

select @mes = right(@periodo,4)+left(@periodo,2)

--**************************************************************************************
select @sql= 'Actualiza montos equipos'
--**************************************************************************************
exec usp_Cascadalog @sql

update a set mto_equipos= b.monto
from scl.facturacion_scl_hist a inner join [servcluprod1\PRDCLINS01].tablas.dbo.facturacion_equipos b
on a.cod_tipdoc = b.cod_tipdocum and a.num_folio = b.num_folio
where mes_fact = @mes  
option(maxdop 1)

--**************************************************************************************
select @sql= 'Aplicar Pagos'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query = ' update fact set fact.Fec_Pago = co.Fec_Pago     '+char(13)+char(10)
+' From scl.Facturacion_scl_hist fact, cascadas.scl.co_cancel co  '+char(13)+char(10)
+' where Fact.Origen in (''SCL'') and fact.num_cuota is not null  '+char(13)+char(10)
+' and Fact.Cod_Client = co.Cod_Cliente       '+char(13)+char(10)
+' and co.Cod_Tipdocum = Fact.Cod_Tipdoc      '+char(13)+char(10)
+' and Fact.Num_Folio = co.Num_Folio          '+char(13)+char(10)
+' and Fact.Num_cuota = co.Num_cuota          '+char(13)+char(10)
+' and fact.sec_cuota = co.sec_cuota          '+char(13)+char(10)
+' and fact.Fec_Pago is null option (maxdop 1)'+char(13)+char(10)
exec(@query)

select @query = ' update fact set fact.Fec_Pago = co.Fec_Pago    '+char(13)+char(10)
+' From scl.Facturacion_scl_hist fact, cascadas.scl.co_cancel co '+char(13)+char(10)
+' where Fact.Origen in (''SCL'') and fact.num_cuota is null     '+char(13)+char(10)
+' and Fact.Cod_Client = co.Cod_Cliente       '+char(13)+char(10)
+' and co.Cod_Tipdocum = Fact.Cod_Tipdoc      '+char(13)+char(10)
+' and Fact.Num_Folio = co.Num_Folio          '+char(13)+char(10)
+' and fact.Fec_Pago is null option (maxdop 1)'+char(13)+char(10)
exec(@query)

--**************************************************************************************
select @sql= 'Fin Aplicar Pagos'
--**************************************************************************************
exec usp_Cascadalog @sql

end