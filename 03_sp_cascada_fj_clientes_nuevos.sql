USE [Cascadas]
GO
/****** Object:  StoredProcedure [dbo].[usp_051_clientes_nuevos_final]    Script Date: 07/12/2016 10:53:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[usp_051_clientes_nuevos_final]
as


set dateformat dmy
declare @fec_inicio datetime, @fec_fin datetime,@fec_fin2 datetime, @mes CHAR(10)
declare @msg_inicio varchar(50),@sql varchar(4000)
--select @fec_fin=convert(datetime,'01-10-2011')
select @fec_fin=convert(datetime,'01-'+right(convert(varchar,getdate(),105),7))
select @fec_inicio=dateadd(month,-1,@fec_fin)
select @fec_fin2 = dateadd(dd,-1,@fec_fin)
select @mes = convert(varchar(10),dateadd(mm,-1,@fec_fin),120)
select @fec_inicio,@fec_fin,@fec_fin2,@mes,convert(numeric,left(replace(@mes,'-',''),6))
select  @msg_inicio='usp_05_Cascada_Atis'


--Saca Pagos de tranzacciones Atis
exec usp_cascada_log 'Descargando Pagos de los ultimos 13 meses', @msg_inicio
truncate table PAGO
insert into PAGO
(MES,Rut_Cliente,Cliente,Cuenta,num_folio,Tramo,Pagos)
select Mes = left(convert(varchar,MVTO_FCH_EMISION,112),6),
		Rut_Cliente = right('000000000000000000000000000000'
		+ltrim(rtrim(Dmcl_Rut_Cliente))
		+ltrim(rtrim(Dmcl_Dv_Rut_Cliente)) ,11),
		CLIENTE = CLCN_CLIENTE ,CUENTA = CLCN_CUENTA,MVTO_NRO_DOC_ORIG ,
		Tramo = CASE WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) <=    0 THEN 'Mes0'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between   1 and   30 THEN 'Mes1'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between  31 and   60 THEN 'Mes2'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between  61 and   90 THEN 'Mes3'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between  91 and  120 THEN 'Mes4'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 121 and  150 THEN 'Mes5'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 151 and  180 THEN 'Mes6'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 181 and  210 THEN 'Mes7'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 211 and  240 THEN 'Mes8'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 241 and  270 THEN 'Mes9'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 271 and  300 THEN 'Mes10'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 301 and  330 THEN 'Mes11'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 331 and  360 THEN 'Mes12'
		End ,Pagos = sum(case when (M.TPTS_TP_TRNX_SECUN_ID 
		IN (1,3,5,7,17,19,20,21,23,30,35,44,53,61,64,67,90,103,158,166,167,177,189,190,191,192,194,199,200,205,257,262,272))
		or M.TPTS_TP_TRNX_SECUN_ID is null then mvto_mon_importe_orig else 0 end) 
--from Apre..Apre_Movimientos_atis_Diario m
from APRE..Apre_Movimientos_diario m
where	M.MVTO_EMP_DEUDA_ORI_ID not in 
		(select cod_empresa from ctacte..cta_empresas_excluir where marca in ('P','NF'))
		and tdoc_tp_doc_orig_id in (1)
		and MVTO_FCH_APLICACION>=@fec_inicio and MVTO_FCH_PAGO<@fec_fin2
		and (M.TPTS_TP_TRNX_SECUN_ID 
		IN (1,3,5,7,17,19,20,21,23,30,35,44,53,61,64,67,90,103,158,166,167,177,189,190,191,192,194,199,200,205,257,262,272))
--		or M.TPTS_TP_TRNX_SECUN_ID is null)
Group by left(convert(varchar,MVTO_FCH_EMISION,112),6),
		right('000000000000000000000000000000'
		+ltrim(rtrim(Dmcl_Rut_Cliente))
		+ltrim(rtrim(Dmcl_Dv_Rut_Cliente)) ,11),CLCN_CLIENTE,CLCN_CUENTA,MVTO_NRO_DOC_ORIG ,
		CASE WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) <= 0 THEN 'Mes0'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 1 and 30 THEN 'Mes1'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 31 and 60  THEN 'Mes2'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 61 and 90 THEN 'Mes3'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 91 and  120 THEN 'Mes4'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 121 and  150 THEN 'Mes5'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 151 and  180 THEN 'Mes6'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 181 and  210 THEN 'Mes7'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 211 and  240 THEN 'Mes8'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 241 and  270 THEN 'Mes9'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 271 and  300 THEN 'Mes10'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 301 and  330 THEN 'Mes11'
		WHEN DATEDIFF(dd,MVTO_FCH_VENCIMIENTO,MVTO_FCH_PAGO) between 331 and  360 THEN 'Mes12'
		End
OPTION (maxdop 1)
update PAGO set Pagos = pagos*-1 where pagos <0 OPTION (maxdop 1)
exec usp_cascada_log 'Aplicando Pagos por tramos a los ultimos 13 meses', @msg_inicio

exec usp_cascada_log 'Mes0', @msg_inicio
update  Cascadas..Cscda_Atis_Facturas set Mes0 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes0') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes1', @msg_inicio
--45 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes1 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes1') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0 
OPTION (maxdop 1)

exec usp_cascada_log 'Mes2', @msg_inicio
--32 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes2 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes2') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes3', @msg_inicio
--18 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes3 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes3') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes4', @msg_inicio
--18 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes4 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes4') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes5', @msg_inicio
--14 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes5 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes5') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes6', @msg_inicio
--16 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes6 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes6') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes7', @msg_inicio
--24 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes7 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes7') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes8', @msg_inicio
--14 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes8 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes8') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes9', @msg_inicio
--14 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes9 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes9') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes10', @msg_inicio
--12 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes10 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes10') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes11', @msg_inicio
--12 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes11 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes11') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

exec usp_cascada_log 'Mes12', @msg_inicio
--10 Minutos
update  Cascadas..Cscda_Atis_Facturas set Mes12 =f.facturado
From  Cascadas..Cscda_Atis_Facturas f, PAGO p
where f.num_folio = p.num_folio
and Tramo in ('Mes12') and (mes0+mes1+mes2+mes3+mes4+mes5+mes6+mes7+mes8+mes9+mes10+mes11+mes12)=0
OPTION (maxdop 1)

----marca carterizados
--update a set carterizado = 'SI'
--from Cascadas..Cscda_Atis_Facturas a 
--where mes = year(@fec_inicio)*100+month(@fec_inicio)
--and a.segmento ='CARTERIZADO'
--OPTION (maxdop 1)

--update a set carterizado = 'NO'
--from Cascadas..Cscda_Atis_Facturas a 
--where segmento = 'NO CARTERIZ' or carterizado is null
--OPTION (maxdop 1)

--update a set prod_agrup = 'BA_SAT'
--from cscda_atis_facturas a inner join parque_bas b
--on a.cuenta = b.cuenta
--where a.mes >=201312
--option(maxdop 1)

update a set prod_agrup = 'BA_SAT'
from cscda_atis_facturas a inner join cascadas..parque_bas_cscda b
on a.cuenta = b.cuenta
where a.mes >=201312
option(maxdop 1)


exec usp_cascada_log 'Fin Aplicacion Pagos', @msg_inicio