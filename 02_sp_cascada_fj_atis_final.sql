USE [Cascadas]
GO
/****** Object:  StoredProcedure [dbo].[usp_05_Cascada_Atis_final]    Script Date: 07/12/2016 10:52:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [dbo].[usp_05_Cascada_Atis_final]
as

set dateformat dmy
declare @fec_inicio datetime
declare @fec_fin datetime, @mes CHAR(10)
select @fec_fin=convert(datetime,'01-'+right(convert(varchar,getdate(),105),7))
--select @fec_fin=convert(datetime,'01-'+right(convert(varchar,dateadd(month,-1,getdate()),105),7))
select @mes = left(convert(varchar(10),dateadd(mm,-1,@fec_fin),112),6)
select @fec_inicio=dateadd(month,-1,@fec_fin)
select @mes,@fec_inicio,@fec_fin,year(@fec_inicio)*100+month(@fec_inicio),year(@fec_fin)*100+month(@fec_fin)

declare @msg_inicio varchar(50)

select  @msg_inicio='usp_05_Cascada_Atis'

exec usp_cascada_log 'Extrayendo Facturacion del Mes', @msg_inicio


--YEAR(M.MVTO_FCH_EMISION)*100+MONTH(M.MVTO_FCH_EMISION)

truncate table FACTURA --select * from FACTURA
insert into FACTURA
(Mes,SEGMENTO,Rut_Cliente,CLIENTE,CUENTA,num_folio,fec_vencim,ciclo,FACTURADO)
select left(convert(varchar,MVTO_FCH_EMISION,112),6) as Mes,
		CASE WHEN SGCL_SEGMENTO_CLTE_ID IN (0, 1) or SGCL_SEGMENTO_CLTE_ID is null THEN 'RESIDENCIAL' 
		WHEN SGCL_SEGMENTO_CLTE_ID IN (2) THEN 'CARTERIZADO' 
		WHEN SGCL_SEGMENTO_CLTE_ID IN (3) THEN 'EMPRESAS' 
		WHEN SGCL_SEGMENTO_CLTE_ID IN (4) THEN 'MAYORISTAS' 
		WHEN SGCL_SEGMENTO_CLTE_ID IN (7) THEN 'NO CARTERIZ'
		END as SEGMENTO,
		right('000000000000000000000000000000'
		+ltrim(rtrim(Dmcl_Rut_Cliente))
		+ltrim(rtrim(Dmcl_Dv_Rut_Cliente)) ,11) as Rut_Cliente,
		CLCN_CLIENTE as CLIENTE,CLCN_CUENTA as CUENTA,MVTO_NRO_DOC_ORIG as num_folio,MVTO_FCH_VENCIMIENTO,
		CLFC_CICLO_FACTURACION_ID,
		sum(mvto_mon_importe_orig) as FACTURADO
from APRE..Apre_Movimientos_diario m
where	M.TPTS_TP_TRNX_SECUN_ID IN (100) 
		and M.MVTO_EMP_DEUDA_ORI_ID not in (select cod_empresa from ctacte..cta_empresas_excluir where marca in ('P','NF'))
		and tdoc_tp_doc_orig_id in (1)
		and M.MVTO_FCH_EMISION>=@fec_inicio and M.MVTO_FCH_EMISION<@fec_fin
Group by left(convert(varchar,MVTO_FCH_EMISION,112),6),
		right('000000000000000000000000000000'
		+ltrim(rtrim(Dmcl_Rut_Cliente))
		+ltrim(rtrim(Dmcl_Dv_Rut_Cliente)) ,11),
		CLCN_CLIENTE,CLCN_CUENTA,MVTO_NRO_DOC_ORIG ,MVTO_FCH_VENCIMIENTO,CLFC_CICLO_FACTURACION_ID,
		CASE WHEN SGCL_SEGMENTO_CLTE_ID IN (0, 1) or SGCL_SEGMENTO_CLTE_ID is null THEN 'RESIDENCIAL' 
		WHEN SGCL_SEGMENTO_CLTE_ID IN (2) THEN 'CARTERIZADO' 
		WHEN SGCL_SEGMENTO_CLTE_ID IN (3) THEN 'EMPRESAS' 
		WHEN SGCL_SEGMENTO_CLTE_ID IN (4) THEN 'MAYORISTAS'
 		WHEN SGCL_SEGMENTO_CLTE_ID IN (7) THEN 'NO CARTERIZ'
		END
OPTION (maxdop 1)

exec usp_cascada_log 'Inicio marcas', @msg_inicio
exec usp_cascada_log 'Incorporando Informacion de Producto al ultimo mes', @msg_inicio

update a set a.Prod_Agrup = b.Prod
From Factura a inner join Parque_Resumen_atis  b 
on a.cliente =  b.cliente and a.cuenta = b.cuenta and a.mes = b.mes
where prod_agrup is null

update a set a.Prod_Agrup = b.Prod
From Factura a inner join Parque_Resumen_atis  b 
on a.cliente =  b.cliente and a.cuenta = b.cuenta 
where prod_agrup is null

update a set a.region = b.region
From Factura a inner join Parque_Resumen_atis  b 
on a.cliente =  b.cliente and a.cuenta = b.cuenta 
where a.region is null

update Factura set region='13' where region is null

exec usp_cascada_log 'Incorporando Informacion Carterizados', @msg_inicio

update a set COD_SGM_CTA_CD= a.COD_SBG_CTA_CD
from infocuenta a
where isnumeric(a.COD_SGM_CTA_CD) <>1 option(maxdop 1)

--update a set segmento = 'CARTERIZADO'
--from Factura a inner join infocuenta b
--on a.cliente = b.cod_cli_cd and a.cuenta = b.cod_cta_cd 
--and b.COD_SGM_CTA_CD in('000000131','000000132','000000133','000000137','000000141','000000142','000000143','000000150')

--update a set segmento = 'NO CARTERIZ'
--from Factura a inner join infocuenta b
--on a.cliente = b.cod_cli_cd and a.cuenta = b.cod_cta_cd 
--and b.COD_SGM_CTA_CD in('000000135','000000160','000000171','000000172','000000173','000000181','000000182','000000183','000000199')

update a set segmento=coalesce(b.categoria_new,'PERSONAS')
from Factura a left join (
		SELECT cod_cli_cd,cod_cta_cd,categoria_new from infocuenta c inner join ctacte.dbo.cta_tipo_segmento d on c.COD_SGM_CTA_CD='000000'+convert(varchar,d.cod_segmento)
		group by cod_cli_cd,cod_cta_cd,categoria_new ) b
on a.cliente = b.cod_cli_cd and a.cuenta = b.cod_cta_cd
option(maxdop 1)

update Factura set segmento='PERSONAS' 	where segmento in ('RESIDENCIAL','NO CARTERIZ','CARTERIZADO')
update Factura set segmento='GRANDES' 	where segmento = 'EMPRESAS'
update Factura set segmento='PERSONAS' 	where segmento is null

exec usp_cascada_log 'Incorporando Informacion de Antiguedad Cliente', @msg_inicio
--mrca estado_clientes
update factura
set estado_cliente ='NUEVO'
from factura
where cuenta in (select codigo_cuenta 
				from ctacte..parque_stb_parque_alta 
				where convert(datetime,fec_alta,120) between dateadd(mm,-7,@fec_inicio) and @fec_inicio)
--				where datediff(d,fec_alta,@mes) between 0 and 180)
and mes =@mes
option (maxdop 1)

update cscda_atis_facturas --Factura
set estado_cliente = 'ANTIGUO'
where estado_cliente is null
OPTION (maxdop 1)

exec usp_cascada_log 'Incorporando Informacion de ciclo7 y fwt', @msg_inicio

--marca ciclo 7
update a set cod_plan = 1
from Factura a 
inner join inteligencia_cobros.dbo.Ciclo7_parque_lineas b
on a.cuenta = b.codigo_cuenta
where mes = @mes
OPTION (maxdop 1)

--marca FWT
update a set cod_plan = 2
from Factura a 
inner join inteligencia_cobros.dbo.FWT b
on a.cuenta = b.cuenta
where a.mes = @mes
OPTION (maxdop 1)

exec usp_cascada_log 'Incorporando Informacion de Portados', @msg_inicio

--marca portados IN
update a set portabilidad = 'PORT IN'
from Factura a 
inner join inteligencia_cobros.dbo.Portabilidad b
on a.cuenta = b.cuenta_atis and b.rnd =317 and a.mes >= year(b.fvc)*100+month(b.fvc)
OPTION (maxdop 1)

--marca portados OUT
update a set portabilidad = 'PORT OUT'
from Factura a 
inner join inteligencia_cobros.dbo.Portabilidad b
on a.cuenta = b.cuenta_atis and b.Dnd =317 and a.mes >= year(b.fvc)*100+month(b.fvc)
OPTION (maxdop 1)

update Factura
set portabilidad = 'NO PORTADO'
where portabilidad is null
OPTION (maxdop 1)

exec usp_cascada_log 'Fin marcas', @msg_inicio

exec usp_cascada_log 'Incorporando informacion de Facturacion al consolidado por Cliente Cuenta Historico', @msg_inicio

insert into Cascadas..Cscda_Atis_Facturas
(Mes,Segmento,Rut_Cliente,Cliente,Cuenta,num_folio,Facturado,Region,
Cant_Abonados,STB,BA,TV,PROD_Agrup,Migrado,
Mes0,Mes1,Mes2,Mes3,Mes4,Mes5,Mes6,Mes7,Mes8,Mes9,Mes10,Mes11,Mes12,fec_vencim,estado_cliente,portabilidad,valor,cod_plan,ciclo,meses)
select Mes,Segmento,Rut_Cliente,Cliente,Cuenta,num_folio,Facturado,Region,
Cant_Abonados,STB,BA,TV,PROD_Agrup,Migrado,
0,0,0,0,0,0,0,0,0,0,0,0,0,fec_vencim,estado_cliente,portabilidad,valor,cod_plan,ciclo,
case when estado_cliente ='NUEVO' then 1 else 0 end 
From Factura
OPTION (maxdop 1)

exec usp_cascada_log 'Marca Vigentes', @msg_inicio
update a set valor = 'NO VIGENTE'
from cscda_atis_facturas a
where mes = @mes
option(maxdop 1)

update a set valor ='VIGENTE'
from cscda_atis_facturas a inner join vigentes_fija b
on a.cuenta = b.codigo_cuenta
where a.mes =@mes
option(maxdop 1)

--exec usp_cascada_log 'Marca Riesgos', @msg_inicio
--update a set riesgo=case when b.p_fl_target1_agrup between 2 and 21 then 1
--						when (b.p_fl_target1_agrup =1) or (b.p_fl_target1_agrup between 22 and 60) then 2
--						when b.p_fl_target1_agrup between 61 and 80 then 3
--						when b.p_fl_target1_agrup between 81 and 100 then 4
--					else 0 end
--from cscda_atis_facturas a inner join mfp_personas b
--on a.cliente = b.cliente 
--where a.mes= @mes
--option(maxdop 1)

--update a set riesgo=case when b.p_fl_target1_agrup <=5 then 1
--						when b.p_fl_target1_agrup between 6 and 50 then 2
--						when b.p_fl_target1_agrup between 51 and 80 then 3
--						when b.p_fl_target1_agrup between 81 and 100 then 4
--					else 0 end
--from cscda_atis_facturas a inner join mfp_negocios b
--on a.cliente = b.cliente 
--where a.mes= @mes
--option(maxdop 1)

exec usp_cascada_log 'Marca Riesgos', @msg_inicio

update a set riesgo=case when b.rut_riesgo_score ='RB' then 1
						 when b.rut_riesgo_score ='RM' then 2
						 when b.rut_riesgo_score ='RA' then 3
						 when b.rut_riesgo_score ='RS' then 4
					else 0 end
from cscda_atis_facturas a inner join fags_MFP_new b
on cascadas.dbo.fn_rutscl(a.rut_cliente) = cascadas.dbo.fn_rutscl(convert(varchar,ltrim(rtrim(b.rut))) +'-'+ convert(varchar,ltrim(rtrim(b.dv)))) collate database_default
where a.mes=@mes
option(maxdop 1)

exec usp_cascada_log 'Marca Riesgos Segun modelo antiguo', @msg_inicio

update a set riesgo=case when b.codigo_tipo_riesgo ='RBM' then 1
						 when b.codigo_tipo_riesgo ='RME' then 2
						 when b.codigo_tipo_riesgo ='RAM' then 3
					else 0 end
from cscda_atis_facturas a inner join
		(
		select rut,min(codigo_tipo_riesgo) as codigo_tipo_riesgo
		from fags_riesgo_mfp 
		group by rut
		)b 
--on cascadas.dbo.fn_rutscl(a.rut_cliente) = cascadas.dbo.fn_rutscl(ltrim(rtrim(b.rut))) collate database_default
on right(a.rut_cliente,10) = b.rut collate database_default
where a.mes=@mes and riesgo is null
option(maxdop 1)

UPDATE cscda_atis_facturas SET DES_RIESGO='BAJO'  WHERE RIESGO='1' AND MES=@mes
UPDATE cscda_atis_facturas SET DES_RIESGO='MEDIO' WHERE RIESGO='2' AND MES=@mes
UPDATE cscda_atis_facturas SET DES_RIESGO='ALTO'  WHERE RIESGO='3' AND MES=@mes
UPDATE cscda_atis_facturas SET DES_RIESGO='ALTO'  WHERE RIESGO='4' AND MES=@mes
UPDATE cscda_atis_facturas SET DES_RIESGO='ND'    WHERE RIESGO IS NULL AND MES=@mes


exec usp_cascada_log 'Fin Atis_final', @msg_inicio