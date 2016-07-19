USE [Cascadas]
GO
/****** Object:  StoredProcedure [dbo].[usp_06_resumen_cascada_final]    Script Date: 07/12/2016 10:54:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[usp_06_resumen_cascada_final]
as
Begin
set dateformat dmy
declare @msg_inicio varchar(50)
select  @msg_inicio='usp_05_Cascada_Atis'

exec usp_cascada_log 'Procesando Resumen Cascada Recupero', @msg_inicio
--Resumen Cascada Recupero
truncate table Cascadas..Cscda_Atis_Recupero
insert into Cascadas..Cscda_Atis_Recupero
(Mes,Segmento,region,Migrado,Prod_Agrup,FACTURADO,Mes0,Mes1,Mes2,Mes3,Mes4,Mes5,Mes6,Mes7,Mes8,Mes9,Mes10,Mes11,Mes12,Antiguedad,Portabilidad,Carterizado,cod_plan,ciclo,riesgo) 
select Mes,segmento 
,region,Migrado,Prod_Agrup, 
		sum(Convert(numeric(18,0),Facturado)) as FACTURADO,
		sum(Convert(numeric(18,0),isnull(Mes0,0)))  as Mes0,
		sum(Convert(numeric(18,0),isnull(Mes1,0))) as Mes1,
		sum(Convert(numeric(18,0),isnull(Mes2,0))) as Mes2,
		sum(Convert(numeric(18,0),isnull(Mes3,0))) as Mes3,
		sum(Convert(numeric(18,0),isnull(Mes4,0))) as Mes4,
		sum(Convert(numeric(18,0),isnull(Mes5,0))) as Mes5,
		sum(Convert(numeric(18,0),isnull(Mes6,0))) as Mes6,
		sum(Convert(numeric(18,0),isnull(Mes7,0))) as Mes7,
		sum(Convert(numeric(18,0),isnull(Mes8,0))) as Mes8,
		sum(Convert(numeric(18,0),isnull(Mes9,0))) as Mes9,
		sum(Convert(numeric(18,0),isnull(Mes10,0))) as Mes10,
		sum(Convert(numeric(18,0),isnull(Mes11,0))) as Mes11,
		sum(Convert(numeric(18,0),isnull(Mes12,0))) as Mes12,
		case when estado_cliente like 'NUEVO%' then 'NUEVO' else 'ANTIGUO' end,
		Portabilidad,Carterizado,case when valor ='NO VIGENTE' then 3 else cod_plan end as cod_plan,
		case when ciclo in (7,1,2,3) or ciclo is null then 1 
			 when ciclo in (4,5,6) then 4
			 when ciclo in (0,8,9,10) then 8  
		else ciclo end as ciclo,riesgo
From Cascadas..Cscda_Atis_Facturas
where mes in
		(select top 18 Mes From Cascadas..Cscda_Atis_Facturas Group by Mes Order by Mes Desc)
Group by Mes,segmento, 
region,Migrado,Prod_Agrup,
case when estado_cliente like 'NUEVO%' then 'NUEVO' else 'ANTIGUO' end,
Portabilidad,Carterizado,case when valor ='NO VIGENTE' then 3 else cod_plan end,
case when ciclo in (7,1,2,3) or ciclo is null then 1 
			 when ciclo in (4,5,6) then 4
			 when ciclo in (0,8,9,10) then 8  
		else ciclo end,riesgo
OPTION (maxdop 1)

update Cascadas..Cscda_Atis_Recupero set prod_agrup = 'Sin Prod'
where prod_agrup is null
OPTION (maxdop 1)

exec usp_cascada_log 'Procesando Resumen Cascadas por Cliente', @msg_inicio
--Resumen Cascadas por Cliente
truncate table Cascadas..Cscda_Atis_CteCta
insert into Cascadas..Cscda_Atis_CteCta
(Prod_Agrup,Segmento,region,Migrado,Mes,Total,Mes0,Mes1,Mes2,Mes3,Mes4,Mes5,Mes6,Mes7,Mes8,Mes9,Mes10,Mes11,Mes12,Antiguedad,Portabilidad,Carterizado,cod_plan,ciclo,riesgo) 
Select Prod_Agrup,segmento,0,Migrado,Mes,Count(rtrim(Cliente)+rtrim(Cuenta)) as Total,
			Mes0= sum(Case when coalesce(Mes0,0) >= Facturado then 1 else 0 end),
			Mes1= sum(Case when coalesce(Mes1,0) > 0 
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)) >= Facturado then 1 else 0 end),
			Mes2= sum(Case when coalesce(Mes2,0) > 0 
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)) >= Facturado 
				  then 1 else 0 end),
			Mes3= sum(Case when coalesce(Mes3,0) > 0  
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)) >= Facturado then 1 else 0 end),
			Mes4= sum(Case when coalesce(Mes4,0) > 0   
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)) >= Facturado then 1 else 0 end),
			Mes5= sum(Case when coalesce(Mes5,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)) >= Facturado 
				  then 1 else 0 end),
			Mes6= sum(Case when coalesce(Mes6,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)) >= Facturado 
				  then 1 else 0 end),
			Mes7= sum(Case when coalesce(Mes7,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)) >= Facturado 
				  then 1 else 0 end),
			Mes8= sum(Case when coalesce(Mes8,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)) >= Facturado 
				  then 1 else 0 end),
			Mes9= sum(Case when coalesce(Mes9,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)
				  +coalesce(Mes9,0)) >= Facturado 
				  then 1 else 0 end),
			Mes10= sum(Case when coalesce(Mes10,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)
				  +coalesce(Mes9,0)+coalesce(Mes10,0)) >= Facturado 
				  then 1 else 0 end),
			Mes11= sum(Case when coalesce(Mes11,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)
				  +coalesce(Mes9,0)+coalesce(Mes10,0)
				  +coalesce(Mes11,0)) >= Facturado 
				  then 1 else 0 end),
			Mes12= sum(Case when coalesce(Mes12,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)
				  +coalesce(Mes9,0)+coalesce(Mes10,0)
				  +coalesce(Mes11,0)+coalesce(Mes12,0)) >= Facturado 
				  then 1 else 0 end),
			case when estado_cliente ='NUEVO' then 'NUEVO' else 'ANTIGUO' end,
			Portabilidad,Carterizado,case when valor ='NO VIGENTE' then 3 else cod_plan end as cod_plan,
			case when ciclo in (7,1,2,3) or ciclo is null then 1 
			 when ciclo in (4,5,6) then 4
			 when ciclo in (0,8,9,10) then 8  
		else ciclo end as ciclo,riesgo
from Cascadas..Cscda_Atis_Facturas 
where mes in
		(select top 18 Mes From Cascadas..Cscda_Atis_Facturas
		Group by Mes
		Order by Mes Desc)
Group by Prod_Agrup,segmento,Migrado,Mes, 
case when estado_cliente ='NUEVO' then 'NUEVO' else 'ANTIGUO' end,
Portabilidad,Carterizado,case when valor ='NO VIGENTE' then 3 else cod_plan end,
			case when ciclo in (7,1,2,3) or ciclo is null then 1 
			 when ciclo in (4,5,6) then 4
			 when ciclo in (0,8,9,10) then 8  
		else ciclo end, valor,riesgo 
OPTION (maxdop 1)

update Cascadas..Cscda_Atis_CteCta set prod_agrup = 'Sin Prod'
where prod_agrup is null
OPTION (maxdop 1)

update  Cascadas..Cscda_Atis_Recupero set Tipo_Cliente =
case when migrado = 1 then 'Migrado' else 'Normal' end
OPTION (maxdop 1)

update Cascadas..Cscda_Atis_CteCta set Tipo_Cliente =
case when migrado = 1 then 'Migrado' else 'Normal' end
OPTION (maxdop 1)


exec usp_cascada_log 'Procesando Cascadas por riesgo ($$)', @msg_inicio
--Resumen Cascada Recupero
truncate table Cascadas..Cscda_Atis_Recupero_riesgo
insert into Cascadas..Cscda_Atis_Recupero_riesgo
(Mes,Segmento,region,Migrado,Prod_Agrup,FACTURADO,Mes0,Mes1,Mes2,Mes3,Mes4,Mes5,Mes6,Mes7,Mes8,Mes9,Mes10,Mes11,Mes12,estado_cliente,Portabilidad,Carterizado,cod_plan,ciclo,riesgo) 
select Mes,segmento,0,Migrado,Prod_Agrup, 
		sum(Convert(numeric(18,0),Facturado)) as FACTURADO,
		sum(Convert(numeric(18,0),isnull(Mes0,0)))  as Mes0,
		sum(Convert(numeric(18,0),isnull(Mes1,0))) as Mes1,
		sum(Convert(numeric(18,0),isnull(Mes2,0))) as Mes2,
		sum(Convert(numeric(18,0),isnull(Mes3,0))) as Mes3,
		sum(Convert(numeric(18,0),isnull(Mes4,0))) as Mes4,
		sum(Convert(numeric(18,0),isnull(Mes5,0))) as Mes5,
		sum(Convert(numeric(18,0),isnull(Mes6,0))) as Mes6,
		sum(Convert(numeric(18,0),isnull(Mes7,0))) as Mes7,
		sum(Convert(numeric(18,0),isnull(Mes8,0))) as Mes8,
		sum(Convert(numeric(18,0),isnull(Mes9,0))) as Mes9,
		sum(Convert(numeric(18,0),isnull(Mes10,0))) as Mes10,
		sum(Convert(numeric(18,0),isnull(Mes11,0))) as Mes11,
		sum(Convert(numeric(18,0),isnull(Mes12,0))) as Mes12,
		case when estado_cliente ='NUEVO' then 'NUEVO' else 'ANTIGUO' end,
		Portabilidad,Carterizado,cod_plan,
			case when ciclo in (7,1,2,3) or ciclo is null then 1 
			 when ciclo in (4,5,6) then 4
			 when ciclo in (0,8,9,10) then 8  
		else ciclo end as ciclo,riesgo
From Cascadas..Cscda_Atis_Facturas
where mes in
		(select top 18 Mes From Cascadas..Cscda_Atis_Facturas
		Group by Mes
		Order by Mes Desc)
Group by Mes,segmento, 
Migrado,Prod_Agrup,
case when estado_cliente ='NUEVO' then 'NUEVO' else 'ANTIGUO' end,
Portabilidad,Carterizado,cod_plan,
			case when ciclo in (7,1,2,3) or ciclo is null then 1 
			 when ciclo in (4,5,6) then 4
			 when ciclo in (0,8,9,10) then 8  
		else ciclo end , riesgo
OPTION (maxdop 1)
/*
exec usp_cascada_log 'Procesando Resumen Cascadas por Cliente Riesgo (QQ)', @msg_inicio
--Resumen Cascadas por Cliente
truncate table Cascadas..Cscda_Atis_CteCta_riesgo
insert into Cascadas..Cscda_Atis_CteCta_riesgo
(Prod_Agrup,Segmento,region,Migrado,Mes,Total,Mes0,Mes1,Mes2,Mes3,Mes4,Mes5,Mes6,Mes7,Mes8,Mes9,Mes10,Mes11,Mes12,Antiguedad,Portabilidad,Carterizado,cod_plan,ciclo,riesgo) 
Select Prod_Agrup,case when Segmento in('NEGOCIOS','PYMES','CARTERIZADO') then 'CARTERIZADO'
			       when segmento in('NEGOCIOS','PYMES','NO Carteriz') then 'NO CARTERIZ' 
else segmento end,0,Migrado,Mes,Count(rtrim(Cliente)+rtrim(Cuenta)) as Total,
			Mes0= sum(Case when coalesce(Mes0,0) >= Facturado then 1 else 0 end),
			Mes1= sum(Case when coalesce(Mes1,0) > 0 
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)) >= Facturado then 1 else 0 end),
			Mes2= sum(Case when coalesce(Mes2,0) > 0 
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)) >= Facturado 
				  then 1 else 0 end),
			Mes3= sum(Case when coalesce(Mes3,0) > 0  
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)) >= Facturado then 1 else 0 end),
			Mes4= sum(Case when coalesce(Mes4,0) > 0   
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)) >= Facturado then 1 else 0 end),
			Mes5= sum(Case when coalesce(Mes5,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)) >= Facturado 
				  then 1 else 0 end),
			Mes6= sum(Case when coalesce(Mes6,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)) >= Facturado 
				  then 1 else 0 end),
			Mes7= sum(Case when coalesce(Mes7,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)) >= Facturado 
				  then 1 else 0 end),
			Mes8= sum(Case when coalesce(Mes8,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)) >= Facturado 
				  then 1 else 0 end),
			Mes9= sum(Case when coalesce(Mes9,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)
				  +coalesce(Mes9,0)) >= Facturado 
				  then 1 else 0 end),
			Mes10= sum(Case when coalesce(Mes10,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)
				  +coalesce(Mes9,0)+coalesce(Mes10,0)) >= Facturado 
				  then 1 else 0 end),
			Mes11= sum(Case when coalesce(Mes11,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)
				  +coalesce(Mes9,0)+coalesce(Mes10,0)
				  +coalesce(Mes11,0)) >= Facturado 
				  then 1 else 0 end),
			Mes12= sum(Case when coalesce(Mes12,0) > 0    
				  and (coalesce(Mes0,0)+coalesce(Mes1,0)+coalesce(Mes2,0)
				  +coalesce(Mes3,0)+coalesce(Mes4,0)+coalesce(Mes5,0)
				  +coalesce(Mes6,0)+coalesce(Mes7,0)+coalesce(Mes8,0)
				  +coalesce(Mes9,0)+coalesce(Mes10,0)
				  +coalesce(Mes11,0)+coalesce(Mes12,0)) >= Facturado 
				  then 1 else 0 end),
			case when estado_cliente ='NUEVO' then 'NUEVO' else 'ANTIGUO' end,
			Portabilidad,Carterizado,cod_plan,
			case when ciclo in (7,1,2,3) or ciclo is null then 1 
			 when ciclo in (4,5,6) then 4
			 when ciclo in (0,8,9,10) then 8  
		else ciclo end as ciclo,riesgo
from Cascadas..Cscda_Atis_Facturas 
where mes in
		(select top 18 Mes From Cascadas..Cscda_Atis_Facturas
		Group by Mes
		Order by Mes Desc)
Group by Prod_Agrup,case when Segmento in('NEGOCIOS','PYMES','CARTERIZADO') then 'CARTERIZADO'
			       when segmento in('NEGOCIOS','PYMES','NO Carteriz') then 'NO CARTERIZ' 
else segmento end,Migrado,Mes, 
case when estado_cliente ='NUEVO' then 'NUEVO' else 'ANTIGUO' end,
Portabilidad,Carterizado,cod_plan,
			case when ciclo in (7,1,2,3) or ciclo is null then 1 
			 when ciclo in (4,5,6) then 4
			 when ciclo in (0,8,9,10) then 8  
		else ciclo end , riesgo
OPTION (maxdop 1)
*/

exec usp_cascadalog 'Resumen Cascadas Fija'

exec usp_cascada_region_dia_fija

exec usp_cascada_log 'Fin Proceso Resumen Cascadas', @msg_inicio

End