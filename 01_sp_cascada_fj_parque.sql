USE [Cascadas]
GO
/****** Object:  StoredProcedure [dbo].[usp_04_carga_parque]    Script Date: 07/12/2016 10:50:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [dbo].[usp_04_carga_parque]
as 
Begin

--****************************************************
--					Parque STB
--****************************************************
set dateformat dmy
declare @fec_inicio datetime
declare @msg_inicio varchar(50), @texto varchar(250), @sql varchar(4000)
declare @hoy datetime

select @msg_inicio='usp_04_carga_parque'
select @hoy=convert(datetime, getdate()-1 ,105)
select @fec_inicio=convert(datetime,convert(char(4),year(dateadd(month,-1,getdate())))+'-'+convert(char(2),month(dateadd(month,-1,getdate())))+'-01',120)
select @hoy,@fec_inicio,YEAR(@fec_inicio)*100+MONTH(@fec_inicio) as Mes

exec usp_cascada_log 'Generando Resumen Parque STB', @msg_inicio
truncate table Parque_total
Insert into Parque_total
select		YEAR(@fec_inicio)*100+MONTH(@fec_inicio) as Mes,
			case when ltrim(rtrim(area_linea_pagador)) 
			in ('','0','000','090','094','095','096','097','098','099') then 0
			when ltrim(rtrim(area_linea_pagador)) in ('320','530') then 
			convert(int,left(ltrim(rtrim(area_linea_pagador)),2))
			else convert(int,ltrim(rtrim(area_linea_pagador)))
			end area,
			Zncnfono,
			area_linea_pagador+telefono_linea_pagador as AreaFono,
			right('00000000000000000000000'+ltrim(rtrim(Rut_cliente))+
			ltrim(rtrim(Rut_cliente_dvf)),11) as Rut_Cliente,
			case when a.tipo_linea_comercial in ('ps_5943','ps_5942','ps_5941') then
			1 else 0 end Migrados,
			sum(convert(numeric(18,0),n_lineas_equivalentes)) as Cant_Lineas,
			1 as STB,
			0 as BA, 
			0 as TV,
			max(substring(fecha_cierre_parque,1,10)) as Fecha_Parque,
			Cliente=convert(numeric(18,0),null),
			Cuenta=convert(numeric(18,0),null)
from Bajas.dbo.Parque_Stb a left join 
			(select Tipo_Linea_Comercial,Familia
			from bajas.dbo.familia_tipo_linea_stb
			group by Tipo_Linea_Comercial,Familia) b
on a.tipo_linea_comercial = b.tipo_linea_comercial
where ltrim(rtrim(Familia)) in ('Control','Postpago') or familia is null and a.marca_linea_stb =1
Group by case when ltrim(rtrim(area_linea_pagador)) 
			in ('','0','000','090','094','095','096','097','098','099') then 0
			when ltrim(rtrim(area_linea_pagador)) in ('320','530') then 
			convert(int,left(ltrim(rtrim(area_linea_pagador)),2))
			else convert(int,ltrim(rtrim(area_linea_pagador)))
			end,Zncnfono,area_linea_pagador+telefono_linea_pagador 
			,right('00000000000000000000000'+ltrim(rtrim(Rut_cliente))+
			ltrim(rtrim(Rut_cliente_dvf)),11),
			case when a.tipo_linea_comercial in ('ps_5943','ps_5942','ps_5941') then
			1 else 0 end

--****************************************************
--					Parque BA
--****************************************************
exec usp_cascada_log 'Resumen Parque BA', @msg_inicio

insert into Parque_total
			(
			Mes,
			Area,
			Zncnfono,
			Areafono,
			Rut_Cliente,
			BA,
			STB,
			TV,
			Migrados,
			Fecha_Parque
			)
select		YEAR(@fec_inicio)*100+MONTH(@fec_inicio),
			case when ltrim(rtrim(area)) 
					in ('','0','000','090','094','095','096','097','098','099') then 0
				when ltrim(rtrim(area)) in ('320','530') then 
					convert(int,left(ltrim(rtrim(area)),2))
				else convert(int,ltrim(rtrim(area)))
			end,
			Zncnfono,
			area+right(rtrim(ltrim(zncnfono)),8),
			right('00000000000000000000000'+ltrim(rtrim(Rut_cliente))+
			ltrim(rtrim(Rut_cliente_dvf)),11),1,0,0,0,max(substring(fecha_cierre_parque,1,10))
from bajas.dbo.parque_ba a left join 
			(select Ps,Familia
			from bajas.dbo.familia_tipo_linea_ba 
			group by Ps,Familia) b
			on rtrim(upper(a.ps))= b.ps 
where ltrim(rtrim(b.Familia)) in ('Control','Postpago') or b.familia is null
group by	case when ltrim(rtrim(area)) 
			in ('','0','000','090','094','095','096','097','098','099') then 0
			when ltrim(rtrim(area)) in ('320','530') then 
			convert(int,left(ltrim(rtrim(area)),2))
			else convert(int,ltrim(rtrim(area)))
			end,Zncnfono,area+right(rtrim(ltrim(zncnfono)),8)
			,right('00000000000000000000000'+ltrim(rtrim(Rut_cliente))+
			ltrim(rtrim(Rut_cliente_dvf)),11)


--****************************************************
--					Parque TV
--****************************************************
exec usp_cascada_log 'Resumen Parque TV', @msg_inicio

insert into Parque_total
			(
			Mes,
			Area,
			Zncnfono,
			Areafono,
			TV,
			STB,
			BA,
			Migrados,
			Fecha_Parque
			)
select		YEAR(@fec_inicio)*100+MONTH(@fec_inicio),
			case when ltrim(rtrim(area)) 
			in ('','0','000','090','094','095','096','097','098','099') then 0
			when ltrim(rtrim(area)) in ('320','530') then 
			convert(int,left(ltrim(rtrim(area)),2))
			else convert(int,ltrim(rtrim(area)))
			end,Zncnfono,area+right(rtrim(ltrim(zncnfono)),8),1,0,0,0,
			max(convert(datetime,fecha_parque))
from bajas.dbo.parque_tv
group by	case when ltrim(rtrim(area)) 
			in ('','0','000','090','094','095','096','097','098','099') then 0
			when ltrim(rtrim(area)) in ('320','530') then 
			convert(int,left(ltrim(rtrim(area)),2))
			else convert(int,ltrim(rtrim(area)))
			end,Zncnfono,area+right(rtrim(ltrim(zncnfono)),8)


exec usp_cascada_log 'Incorporando el Rut al parque TV', @msg_inicio

update TV set tv.Rut_Cliente = stb.rut_cliente
From  Parque_total tv inner join 
			(select Mes,zncnfono,Rut_Cliente 
			from  Parque_total where stb = 1
			Group by Mes,zncnfono,Rut_Cliente) stb
on tv.mes = stb.mes and tv.zncnfono = stb.zncnfono 
where tv.rut_cliente is null


update TV set tv.Rut_Cliente = stb.rut_cliente
From  Parque_total tv inner join 
			(select Mes,areafono,Rut_Cliente 
			from  Parque_total where stb = 1
			Group by Mes,areafono,Rut_Cliente) stb
on tv.mes = stb.mes and tv.areafono = stb.areafono 
where tv.rut_cliente is null


update TV set tv.Rut_Cliente = stb.rut_cliente
From  Parque_total tv inner join 
			(select Mes,zncnfono,Rut_Cliente 
			from  Parque_total where ba = 1
			Group by Mes,zncnfono,Rut_Cliente) stb
on tv.mes = stb.mes and tv.zncnfono = stb.zncnfono 
where tv.rut_cliente is null


update TV set tv.Rut_Cliente = stb.rut_cliente
From  Parque_total tv inner join 
			(select Mes,areafono,Rut_Cliente 
			from  Parque_total where ba = 1
			Group by Mes,areafono,Rut_Cliente) stb
on tv.areafono = stb.areafono 
where tv.rut_cliente is null


update TV set tv.Rut_Cliente = stb.rut_cliente
From  Parque_total tv inner join 
			(select rtrim(ltrim(rut)) as Rut_Cliente,
			rtrim(ltrim(zncnfono)) as  zncnfono
			from bajas..infocliente
			group by rtrim(ltrim(rut)),
			rtrim(ltrim(zncnfono))) stb
on tv.zncnfono = stb.zncnfono   collate database_default
			where tv.rut_cliente is null


exec usp_cascada_log 'Incorporando Rut al Parque TV desde infocliente', @msg_inicio

update TV set tv.Rut_Cliente = stb.rut
From  Parque_total tv inner join 
				(select Rut,right('00000000'+ltrim(rtrim([Cod_Area])),3)+right(
				ltrim(rtrim([Zncnfono])),8) as Areafono
				from bajas..infocliente
				where codigo_cliente is not null and rtrim(ltrim(Codigo_cliente)) not in ('')
						Group by [Rut],right('00000000'+ltrim(rtrim([Cod_Area])),3)+right(
						ltrim(rtrim([Zncnfono])),8)) stb
on tv.areafono = stb.areafono  collate database_default
				where tv.rut_cliente is null


--****************************************************
--					Incorporar los cliente cuenta
--****************************************************
exec usp_cascada_log 'Incorporar Cliente Cuenta en los parques', @msg_inicio

update  Parque_total set Cliente = p.Codigo_Cliente, Cuenta = p.Codigo_Cuenta
From 
			(select Rut,right('00000000'+ltrim(rtrim(Cod_Area)),3)+right(
					ltrim(rtrim(Zncnfono)),8) as Areafono,Codigo_cliente,Codigo_Cuenta
			from bajas..infocliente
			where codigo_cliente is not null and rtrim(ltrim(Codigo_cliente)) not in ('')
					Group by [Rut],right('00000000'+ltrim(rtrim(Cod_Area)),3)+right(
					ltrim(rtrim(Zncnfono)),8),Codigo_cliente,Codigo_Cuenta) p,  
Parque_total a
				where rut_cliente is not null and a.AreaFono =  p.areafono collate Modern_Spanish_CI_AS
				and a.Rut_Cliente collate Modern_Spanish_CI_AS = p.Rut

update  Parque_total set Cliente = p.Codigo_Cliente, Cuenta = p.Codigo_Cuenta
From 
			(select rtrim(ltrim(rut)) as Rut_Cliente,
			rtrim(ltrim(zncnfono)) as  zncnfono,Codigo_Cliente,Codigo_Cuenta
			from bajas..infocliente
			where codigo_cliente is not null and rtrim(ltrim(Codigo_cliente)) not in ('')
			group by rtrim(ltrim(rut)),rtrim(ltrim(zncnfono)),Codigo_Cliente,Codigo_Cuenta) p,  
Parque_total a
		where (a.Cliente is null or a.cliente = 0) and 
		a.zncnfono =  p.zncnfono collate Modern_Spanish_CI_AS
		and a.Rut_Cliente collate Modern_Spanish_CI_AS = p.Rut_Cliente


exec usp_cascada_log 'Generando Resumen Parque', @msg_inicio

--truncate table Parque_Resumen
insert into Parque_Resumen_atis
select 	mes,
		cliente,
		cuenta,
		case when stb =1 and ba=1 and tv=1 then 'TRIO'
		when stb =1 and ba=1 and tv=0 then 'DUO BAF'
		when stb =1 and ba=0 and tv=1 then 'DUO TV'
		when stb =1 and ba=0 and tv=0 then 'STB'	
		when stb =0 and ba=1 and tv=1 then 'BAF + TV'
		when stb =0 and ba=0 and tv=1 then 'TV'
		when stb =0 and ba=1 and tv=0 then 'BAF'
		when stb =0 and ba=0 and tv=0 then 'SIN PROD'
		end Prod,case when Area in (71,73,75) 
		then 7  when Area in (41,42,43) then 8 
		when Area in (68,67) then 11 when Area in (61) then 12
		when Area in (72) then 6 when Area in (2) then 13
		when Area in (32,33,34,35,39) then 5 when Area in (45) then 9
		when Area in (51,53) then 4 when Area in (52) then 3
		when Area in (52) then 3 when Area in (55) then 2
		when Area in (57) then 1 when Area in (58) then 15
		when Area in (64,65) then 10 when Area in (63) then 14
		else 0 end Region
From  (select	mes,Max(Area) as Area,Rut_Cliente,Max(Migrados) as Migrados,
				Cliente,Cuenta,max(isnull(STB,0)) as STB,
				max(isnull(BA,0)) as BA,max(isnull(TV,0)) as TV,
				sum(isnull(Cant_lineas,0)) as Cant_Abonados
		from  Parque_total
		Group by mes,Rut_Cliente,Cliente,Cuenta) a


exec usp_cascada_log 'Carga Riesgo desde Cluster2', @msg_inicio
--if exists(select * from sysobjects where name='mfp_personas')
--	drop table mfp_personas
--set @sql = 'select * into mfp_personas from [servcluprod1\PRDCLINS01].cascada.dbo.mfp_personas_'+convert(char(6),YEAR(@fec_inicio)*100+MONTH(@fec_inicio))+ ' option(maxdop 1)'
--exec(@sql)

--if exists(select * from sysobjects where name='mfp_negocios')
--	drop table mfp_negocios
--set @sql= 'select * into mfp_negocios from [servcluprod1\PRDCLINS01].cascada.dbo.mfp_negocios_'+convert(char(6),YEAR(@fec_inicio)*100+MONTH(@fec_inicio))+ ' option(maxdop 1)'
--exec(@sql)
if exists(select * from sysobjects where name='fags_MFP_new')
drop table fags_MFP_new

select * into fags_MFP_new from [servcluprod2\prdclins02].operacion.dbo.fags_MFP_new

if exists(select * from sysobjects where name='fags_riesgo_mfp')
drop table fags_riesgo_mfp

select * into fags_riesgo_mfp from [servcluprod2\prdclins02].operacion.dbo.fags_riesgo_mfp

exec usp_cascada_log 'Carga Vigentes', @msg_inicio

if exists(select * from sysobjects where name='vigentes_fija')
          drop table vigentes_fija

	select codigo_cliente,codigo_cuenta into vigentes_fija from bajas..infocliente
	group by codigo_cliente,codigo_cuenta 

--select rut_cliente,segmento,zncnfono,area,areafono,fecha_alta,ciclo,cliente,cuenta  into cascadas..parque_bas_cscda  from cascadas..parque_bas where 1 = 2 
--select * from cascadas..parque_bas_cscda

exec usp_cascada_log 'Carga Parque BAS', @msg_inicio

truncate table cascadas..parque_bas_cscda

insert into cascadas..parque_bas_cscda

select rtrim(convert(char,convert(numeric,a.rut_cliente)))+'-'+rtrim(a.rut_cliente_dvf) rut_cliente,b.segmento_gestion,a.zncnfono,a.area,
convert(numeric,(rtrim(a.area)+substring(a.zncnfono,5,8))) areafono,convert(datetime,a.fec_ini_lin,112) fecha_alta,a.ciclo,b.codigo_cliente cliente ,b.codigo_cuenta cuenta
from bajas..parque_ba a left join bajas..infocliente b on a.zncnfono = b.zncnfono collate database_default 
where a.tecnologia = 'SAT' 
and rut_cliente not in ('000010069935','000014430778')

exec usp_cascada_log 'Fin Proceso Parque Resumen', @msg_inicio

End