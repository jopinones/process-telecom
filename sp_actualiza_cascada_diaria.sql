USE [Cascadas]
GO
/****** Object:  StoredProcedure [dbo].[Usp_Actualiza_cascada_diaria]    Script Date: 07/12/2016 10:56:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[Usp_Actualiza_cascada_diaria]
as
begin

declare @fec_ult datetime
declare @qry varchar(2000), @sql varchar(2000)
--********************
--Resumen por dia FIJA
--********************
--saca pagos ultimos 15 dias
--select @fec_ult = max(fec_pago) from cscda_atis_facturas

if exists (select * from sysobjects where name='pagos_semana')
		drop table pagos_semana

select clcn_cliente,clcn_cuenta,MVTO_NRO_DOC_ORIG,convert(char(10),mvto_fch_pago,120) fec_pago,sum(convert(numeric,MVTO_MON_IMPORTE_ORIG)) mto
into pagos_semana
from apre..apre_movimientos_diario 
where mvto_fch_pago >= dateadd(dd,-90,getdate())
and MVTO_EMP_DEUDA_ORI_ID not in (select cod_empresa from ctacte..cta_empresas_excluir where marca in ('P','NF'))
and (TPTS_TP_TRNX_SECUN_ID IN (1,3,5,7,17,19,20,21,23,30,35,44,53,61,64,67,90,103,158,166,167,177,189,190,191,192,194,199,200,205,257,262,272))
group by clcn_cliente,clcn_cuenta,MVTO_NRO_DOC_ORIG,convert(char(10),mvto_fch_pago,120)
option(maxdop 1)

--marca fechas de pago
update dbo.cscda_atis_facturas 
set fec_pago = b.fec_pago
from dbo.cscda_atis_facturas a inner join pagos_semana b
on rtrim(a.num_folio) = rtrim(b.MVTO_NRO_DOC_ORIG) and a.cuenta = b.clcn_cuenta 
where a.fec_pago is null
option (maxdop 1)
--crea resumen para cascada


if exists (select * from sysobjects where name='pagos_semana_m')
		drop table pagos_semana_m

select @qry=' select cod_cliente,cod_tipdocum, num_folio, '+char(13)
		   +' greatest(trunc(fec_efectividad),to_date(''''01-01-1753'''',''''dd-mm-yyyy'''')) as fec_efectividad, '+char(13)
		   +' greatest(trunc(fec_vencimie),to_date(''''01-01-1753'''',''''dd-mm-yyyy''''))  as fec_vencimie, '+char(13)
		   +' greatest(trunc(fec_pago),to_date(''''01-01-1753'''',''''dd-mm-yyyy'''')) as fec_pago, '+char(13)
		   +' num_cuota,sec_cuota,importe_Debe,importe_haber from co_cancelados '+char(13)
		   +' where greatest(trunc(fec_pago),to_date(''''01-01-1753'''',''''dd-mm-yyyy'''')) '+char(13)
		   +' >=  to_date(''''' + rtrim(convert(char,dateadd(dd,-90,getdate()),105)) + ''''',''''dd-mm-yyyy'''') '+char(13)
	       +' and cod_tipdocum not in (67,68,25,74) '+char(13)
		   +' and fec_efectividad>=sysdate-720'

select @sql=' select * into pagos_semana_m'+char(13)+char(10)
		   +' from openquery(BD_SCL,''' + @qry + ''') '
exec(@sql)
--pago de cuotas
update scl.facturacion_scl_hist
set fec_pago = b.fec_pago
from scl.facturacion_scl_hist a inner join pagos_semana_m b
on a.cod_tipdoc = b.cod_tipdocum and a.num_folio = b.num_folio and a.sec_cuota = b.sec_cuota
where a.fec_pago is null option(maxdop 1)

--pago de folio
update scl.facturacion_scl_hist
set fec_pago = b.fec_pago
from scl.facturacion_scl_hist a inner join pagos_semana_m b
on a.cod_tipdoc = b.cod_tipdocum and a.num_folio = b.num_folio 
where a.num_cuota is null and a.fec_pago is null option(maxdop 1)


-- Genera Resumenes (Incluido a la web)

truncate table SCL.cscda_resumen_por_dia_mov
truncate table cscda_resumen_por_dia_fija

update cascada_parametro set fec_actualizacion=convert(varchar,getdate(),105)

exec dbo.usp_cascada_region_dia
exec dbo.usp_cascada_region_dia_fija
exec dbo.Usp_Actualiza_cascada_diaria_web

End