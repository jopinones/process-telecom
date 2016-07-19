USE [Cascadas]
GO
/****** Object:  StoredProcedure [dbo].[usp_cascada_descuentos]    Script Date: 07/12/2016 10:58:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[usp_cascada_descuentos] as 

if exists(select * from sysobjects where name ='resumen_cscda_descto')
		  drop table resumen_cscda_descto

select a.mes, case when Segmento in('NEGOCIOS','PYMES','Carterizado')  then 'CARTERIZADO'
when segmento in('NEGOCIOS','PYMES','No Carteriz') then 'NO CARTERIZ' else segmento end segmento, 
Prod_Agrup, carterizado, case when estado_cliente like 'NUEVO%' then 'NUEVO' else 'ANTIGUO' end estado_cliente, migrado, portabilidad, 
case when (ciclo in(1,2,3,7) or ciclo is null) then 1
when ciclo in(4,5,6) then 4
when ciclo in(8,9,0,10) then 8 end ciclo,
case when datediff(dd,fec_vencim,fec_pago) <=0 then 1
when datediff(dd,fec_vencim,fec_pago) between 1 and 6 then 2
when datediff(dd,fec_vencim,fec_pago) between 7 and 9 then 3
when datediff(dd,fec_vencim,fec_pago) between 10 and 15 then 4
when datediff(dd,fec_vencim,fec_pago) between 16 and 30 then 5
when datediff(dd,fec_vencim,fec_pago) between 31 and 45 then 6
when datediff(dd,fec_vencim,fec_pago) between 46 and 60 then 7
when datediff(dd,fec_vencim,fec_pago) between 61 and 75 then 8
when datediff(dd,fec_vencim,fec_pago) between 76 and 90 then 9
when datediff(dd,fec_vencim,fec_pago) between 91 and 120 then 10
when datediff(dd,fec_vencim,fec_pago) between 121 and 150 then 11
when datediff(dd,fec_vencim,fec_pago) between 151 and 180 then 12
when datediff(dd,fec_vencim,fec_pago) > 180 then 13 else 14 end as tramo,des_riesgo, valor,
sum(convert(numeric,Facturado)) monto_fac, sum(case when fec_pago is not null then convert(numeric,facturado) else 0 end) as monto_pago,
count(*) as Q_ctas, b.descuento,sum(Q_DESC) as Q_DESC,b.entidad,b.mes as mes_desc,b.tipo
into resumen_cscda_descto
from dbo.cscda_atis_facturas a inner join (
		select left(fecha,6) as mes,cliente,cuenta,max(porc_dec) as descuento,max(gestion_dentro_campana) as tipo,
		max(entidad) as entidad,count(*) as Q_DESC from procesos.cobex.cb_moroso_descuentos_hist
		group by left(fecha,6),cliente,cuenta
) b on a.cliente=b.cliente and a.cuenta=b.cuenta
where a.mes in
		(select top 18 Mes From Cascadas..Cscda_Atis_Facturas
		Group by Mes
		Order by Mes Desc)
group by a.mes, case when Segmento in('NEGOCIOS','PYMES','Carterizado')  then 'CARTERIZADO'
when segmento in('NEGOCIOS','PYMES','No Carteriz') then 'NO CARTERIZ' else segmento end, 
Prod_Agrup, carterizado,  case when estado_cliente like 'NUEVO%' then 'NUEVO' else 'ANTIGUO' end, migrado, portabilidad, 
case when (ciclo in(1,2,3,7) or ciclo is null) then 1
when ciclo in(4,5,6) then 4
when ciclo in(8,9,0,10) then 8 end,
case when datediff(dd,fec_vencim,fec_pago) <=0 then 1
when datediff(dd,fec_vencim,fec_pago) between 1 and 6 then 2
when datediff(dd,fec_vencim,fec_pago) between 7 and 9 then 3
when datediff(dd,fec_vencim,fec_pago) between 10 and 15 then 4
when datediff(dd,fec_vencim,fec_pago) between 16 and 30 then 5
when datediff(dd,fec_vencim,fec_pago) between 31 and 45 then 6
when datediff(dd,fec_vencim,fec_pago) between 46 and 60 then 7
when datediff(dd,fec_vencim,fec_pago) between 61 and 75 then 8
when datediff(dd,fec_vencim,fec_pago) between 76 and 90 then 9
when datediff(dd,fec_vencim,fec_pago) between 91 and 120 then 10
when datediff(dd,fec_vencim,fec_pago) between 121 and 150 then 11
when datediff(dd,fec_vencim,fec_pago) between 151 and 180 then 12
when datediff(dd,fec_vencim,fec_pago) > 180 then 13 else 14 end, des_riesgo,valor,
b.descuento,b.entidad,b.mes,b.tipo
option (maxdop 1)

update resumen_cscda_descto set segmento='RESIDENCIAL'	where segmento='NATURALES'
update resumen_cscda_descto set segmento='MICRO'		where segmento like '%NO CARTERIZ%'
UPDATE resumen_cscda_descto SET segmento='MEDIANAS'		WHERE segmento='CARTERIZADO'
UPDATE resumen_cscda_descto SET segmento='GRANDES'		WHERE segmento='EMPRESAS'
UPDATE resumen_cscda_descto SET segmento='PERSONAS'		WHERE segmento='RESIDENCIAL'
UPDATE resumen_cscda_descto SET segmento='MICRO'		WHERE segmento='NO CARTERIZADO'
UPDATE resumen_cscda_descto SET segmento='AUTONOMOS'    WHERE segmento='AUTONOMO'
UPDATE resumen_cscda_descto SET segmento='MICRO'		WHERE segmento='PYMES'
UPDATE resumen_cscda_descto SET segmento='MEDIANAS'		WHERE segmento='NEGOCIOS'

update resumen_cscda_descto set tipo='DESCUENTO' WHERE TIPO IS NULL

update resumen_cscda_descto set entidad=ltrim(rtrim(entidad))