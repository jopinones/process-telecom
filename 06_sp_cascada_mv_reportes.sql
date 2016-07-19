USE [Cascadas]
GO
/****** Object:  StoredProcedure [SCL].[usp_scl_Cscda_06_reportes]    Script Date: 07/12/2016 11:10:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER procedure [SCL].[usp_scl_Cscda_06_reportes]
as
begin
set dateformat dmy
declare @fec_ini datetime, @fec_fin datetime,@fecha datetime
declare @query nvarchar(4000), @sql nvarchar(4000)
declare @periodo char(6)
declare @i int, @ano numeric
declare @archivo char(20),@mes numeric
declare @total numeric

--**************************************************************************************
--Aplicar Pagos por Fec. Venc y Fec. Pago'
--**************************************************************************************
select @i = 0
select @periodo=valor from scl.parametro where parametro='PER_CASCADA'
select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-17,@fec_ini))
select @ano = year(dateadd(mm,-17,@fec_ini))
select @periodo,@fec_ini,@fec_fin,@ano*100+@mes

--**************************************************************************************
--Resumen General 
--**************************************************************************************

select @sql=  'Resumen General'
exec usp_Cascadalog @sql




truncate table cascadas.scl.Resumen_Cascada
select @i = 0
select @periodo=valor from scl.parametro where parametro='PER_CASCADA'
select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-18,@fec_ini))
select @ano = year(dateadd(mm,-18,@fec_ini))
select @archivo = right('000'+rtrim(@mes),2)+rtrim(@ano)
select @query = 'insert into cascadas.scl.Resumen_Cascada select  left(convert(varchar,fec_emisio,112),6) as mes_fact, '+char(13)+char(10)
	       +' origen, emp,des_catego, region,tip_client, case when valor =''NO VIGENTE'' then ''NO VIGENTE'' else tip_plan end as tip_plan, case when pack is null then ''VOZ'' else pack end pack, sum(importe) as Tot_Fact, day(fec_emisio) as dia_emi, '+char(13)+char(10)
		   +' sum(mes_0) as mes_0, sum(mes_0) as Rec_0, '+char(13)+char(10)
	       +' sum(mes_1) as mes_1, sum(mes_1) as Rec_1, '+char(13)+char(10)		
	       +' sum(mes_2) as mes_2, sum(mes_2) as Rec_2, '+char(13)+char(10) 
	       +' sum(mes_3) as mes_3, sum(mes_3) as Rec_3, '+char(13)+char(10) 
	       +' sum(mes_4) as mes_4, sum(mes_4) as Rec_4, '+char(13)+char(10)
	       +' sum(mes_5) as mes_5, sum(mes_5) as Rec_5, '+char(13)+char(10) 		
	       +' sum(mes_6) as mes_6, sum(mes_6) as Rec_6, '+char(13)+char(10) 		
	       +' sum(mes_7) as mes_7, sum(mes_7) as Rec_7, '+char(13)+char(10) 		
	       +' sum(mes_8) as mes_8, sum(mes_8) as Rec_8, '+char(13)+char(10) 		
	       +' sum(mes_9) as mes_9, sum(mes_9) as Rec_9, '+char(13)+char(10) 		
	       +' sum(mes_10) as mes_10,sum(mes_10) as Rec_10, '+char(13)+char(10) 	
	       +' sum(mes_11) as mes_11,sum(mes_11) as Rec_11, '+char(13)+char(10) 	
	       +' sum(mes_12) as mes_12,sum(mes_12) as Rec_12, '+char(13)+char(10) 	
	       +' Estado_Cliente,Portabilidad,Familia_Plan,Carterizado,migracion,valor,des_riesgo,cod_ciclo '+char(13)+char(10) 	
	       +' from SCL.facturacion_scl_hist '+char(13)+char(10)
		   +' where mes_fact in(select top 18 mes_fact from scl.facturacion_scl_hist group by mes_fact order by mes_fact DESC)' + char(13)+char(10)
	       +' and des_catego not in (''ESPECIALES'') '+char(13)+char(10)
--		       +' and (migracion is null or migracion in (''1'',''H'',''HIBRIDO'',''N'',''NORMAL'')) '+char(13)+char(10)
	       +' and origen not in (''SAP'') '+char(13)+char(10)
	       +' Group by left(convert(varchar,fec_emisio,112),6),origen, emp,des_catego, region,tip_client, case when valor =''NO VIGENTE'' then ''NO VIGENTE'' else tip_plan end, case when pack is null then ''VOZ'' else pack end, day(fec_emisio), '+char(13)+char(10)
	       +' Estado_Cliente,Portabilidad,Familia_Plan,Carterizado,migracion,valor,des_riesgo,cod_ciclo option (maxdop 1)'+char(13)+char(10) 	
exec(@query)

update cascadas.scl.Resumen_Cascada set tip_client ='ESPECIAL' where des_catego ='ESPECIAL' and tip_client ='NORMAL'
update cascadas.scl.Resumen_Cascada set tip_client ='ESPECIAL' where des_catego ='ESPECIALISTAS' and tip_client ='NORMAL'
update cascadas.scl.Resumen_Cascada set tip_client ='ESPECIAL' where des_catego ='RELACIONADA' and tip_client ='NORMAL'

--**************************************************************************************
--Resumen por Cod Cliente 
--**************************************************************************************


select @sql=  'Resumen Cliente'
exec usp_Cascadalog @sql


truncate table cascadas.scl.Resumen_Cascada_Cod_Client 
insert into cascadas.scl.Resumen_Cascada_Cod_Client
	(Mes_Fact, origen, emp, des_catego, region,
	tip_client, tip_plan, tip_prod, Tot_Fact, 
	mes_0, Rec_0, mes_1, Rec_1, mes_2, Rec_2, 
	mes_3, Rec_3, mes_4, Rec_4, mes_5, Rec_5, 
	mes_6, Rec_6, mes_7, Rec_7, mes_8, Rec_8, 
	mes_9, Rec_9, mes_10, Rec_10, mes_11, 
	Rec_11, mes_12, Rec_12,Antiguedad,Portabilidad,
	Familia_Plan,Carterizado,migracion,valor,riesgo,ciclo)
select Mes_Fact,origen,'' emp,des_catego, 0, tip_client, case when valor ='NO VIGENTE' then 'NO VIGENTE' else tip_plan end as tip_plan,	case when pack is null then 'VOZ' else pack end Tip_prod,
	Tot_Fact=count(cod_client),
	Mes_0= sum(case when Mes_0 > 0 then 1 else 0 end),
	Rec_0= sum(case when Mes_0 > 0 then 1 else 0 end),
	Mes_1= sum(case when Mes_1 > 0 then 1 else 0 end),
	Rec_1= sum(case when Mes_1 > 0 then 1 else 0 end),
	Mes_2= sum(case when Mes_2 > 0 then 1 else 0 end),
	Rec_2= sum(case when Mes_2 > 0 then 1 else 0 end),
	Mes_3= sum(case when Mes_3 > 0 then 1 else 0 end),
	Rec_3= sum(case when Mes_3 > 0 then 1 else 0 end),
	Mes_4= sum(case when Mes_4 > 0 then 1 else 0 end),
	Rec_4= sum(case when Mes_4 > 0 then 1 else 0 end),
	Mes_5= sum(case when Mes_5 > 0 then 1 else 0 end),
	Rec_5= sum(case when Mes_5 > 0 then 1 else 0 end),
	Mes_6= sum(case when Mes_6 > 0 then 1 else 0 end),
	Rec_6= sum(case when Mes_6 > 0 then 1 else 0 end),
	Mes_7= sum(case when Mes_7 > 0 then 1 else 0 end),
	Rec_7= sum(case when Mes_7 > 0 then 1 else 0 end),
	Mes_8= sum(case when Mes_8 > 0 then 1 else 0 end),
	Rec_8= sum(case when Mes_8 > 0 then 1 else 0 end),
	Mes_9= sum(case when Mes_9 > 0 then 1 else 0 end),
	Rec_9= sum(case when Mes_9 > 0 then 1 else 0 end),
	Mes_10= sum(case when Mes_10 > 0 then 1 else 0 end),
	Rec_10= sum(case when Mes_10 > 0 then 1 else 0 end),
	Mes_11= sum(case when Mes_11 > 0 then 1 else 0 end),
	Rec_11= sum(case when Mes_11 > 0 then 1 else 0 end),
	Mes_12= sum(case when Mes_12 > 0 then 1 else 0 end),
	Rec_12= sum(case when Mes_12 > 0 then 1 else 0 end),
	case when estado_cliente like 'NUEVO%' then 'NUEVO' else 'ANTIGUO' end antiguedad,
	Portabilidad,Familia_Plan, Carterizado,migracion,valor,des_riesgo,cod_ciclo
	from cascadas.scl.facturacion_scl_hist
	where mes_fact in (select top 18 Mes_fact From Cascadas.scl.facturacion_scl_hist
		Group by Mes_fact
		Order by Mes_fact Desc)
	Group by Mes_Fact,origen, des_catego,  tip_client, case when valor ='NO VIGENTE' then 'NO VIGENTE' else tip_plan end, 
	case when pack is null then 'VOZ' else pack end ,case when estado_cliente like 'NUEVO%' then 'NUEVO' else 'ANTIGUO' end ,Portabilidad,
	Familia_Plan, Carterizado,migracion,valor,des_riesgo,cod_ciclo
option(maxdop 1)

update cascadas.scl.Resumen_Cascada_Cod_Client set tip_client ='ESPECIAL' where des_catego ='ESPECIAL' and tip_client ='NORMAL'
update cascadas.scl.Resumen_Cascada_Cod_Client set tip_client ='ESPECIAL' where des_catego ='ESPECIALISTAS' and tip_client ='NORMAL'
update cascadas.scl.Resumen_Cascada_Cod_Client set tip_client ='ESPECIAL' where des_catego ='RELACIONADA' and tip_client ='NORMAL'

--**************************************************************************************
--Resumen por Riesgo_monto
--**************************************************************************************


select @sql=  'Resumen Riesgo'
exec usp_Cascadalog @sql


truncate table cascadas.scl.Resumen_Cascada_Riesgo
select @query = 'insert into cascadas.scl.Resumen_Cascada_Riesgo '+ char(13)+char(10)
		   + ' select  left(convert(varchar,fec_emisio,112),6) mes, '+char(13)+char(10)
	       +' origen, emp,des_catego, tip_client, tip_plan, case when pack is null then ''VOZ'' else pack end as pack,sum(importe) as Tot_Fact, day(fec_emisio) as dia_emi, '+char(13)+char(10)
		   +' sum(mes_0) as mes_0, sum(mes_0) as Rec_0, '+char(13)+char(10)
	       +' sum(mes_1) as mes_1, sum(mes_1) as Rec_1, '+char(13)+char(10)		
	       +' sum(mes_2) as mes_2, sum(mes_2) as Rec_2, '+char(13)+char(10) 
	       +' sum(mes_3) as mes_3, sum(mes_3) as Rec_3, '+char(13)+char(10) 
	       +' sum(mes_4) as mes_4, sum(mes_4) as Rec_4, '+char(13)+char(10)
	       +' sum(mes_5) as mes_5, sum(mes_5) as Rec_5, '+char(13)+char(10) 		
	       +' sum(mes_6) as mes_6, sum(mes_6) as Rec_6, '+char(13)+char(10) 		
	       +' sum(mes_7) as mes_7, sum(mes_7) as Rec_7, '+char(13)+char(10) 		
	       +' sum(mes_8) as mes_8, sum(mes_8) as Rec_8, '+char(13)+char(10) 		
	       +' sum(mes_9) as mes_9, sum(mes_9) as Rec_9, '+char(13)+char(10) 		
	       +' sum(mes_10) as mes_10,sum(mes_10) as Rec_10, '+char(13)+char(10) 	
	       +' sum(mes_11) as mes_11,sum(mes_11) as Rec_11, '+char(13)+char(10) 	
	       +' sum(mes_12) as mes_12,sum(mes_12) as Rec_12, '+char(13)+char(10) 	
	       +' Estado_Cliente,Portabilidad,Familia_Plan,Carterizado,migracion,des_riesgo,valor '+char(13)+char(10) 	
		   +' from SCL.facturacion_scl_hist '+char(13)+char(10)
		   +' where mes_fact in (select top 18 mes_fact from scl.facturacion_scl_hist group by mes_fact order by mes_fact DESC)'+char(13)+char(10)
	       +' and des_catego not in (''ESPECIALES'') '+char(13)+char(10)
	       +' and origen not in (''SAP'') '+char(13)+char(10)
	       +' Group by  left(convert(varchar,fec_emisio,112),6),origen, emp,des_catego,tip_client, tip_plan, case when pack is null then ''VOZ'' else pack end, day(fec_emisio), '+char(13)+char(10)
	       +' Estado_Cliente,Portabilidad,Familia_Plan,Carterizado,migracion,des_riesgo,valor option (maxdop 1)'+char(13)+char(10) 	
exec(@query)
update cascadas.scl.Resumen_Cascada_Riesgo set tip_client ='ESPECIAL' where des_catego ='ESPECIAL' and tip_client ='NORMAL'
update cascadas.scl.Resumen_Cascada_Riesgo set tip_client ='ESPECIAL' where des_catego ='ESPECIALISTAS' and tip_client ='NORMAL'
update cascadas.scl.Resumen_Cascada_Riesgo set tip_client ='ESPECIAL' where des_catego ='RELACIONADA' and tip_client ='NORMAL'

/*--**************************************************************************************
--Resumen por Riesgo Cod Cliente 
--**************************************************************************************
truncate table cascadas.scl.Resumen_Cascada_riesgo_Q
select @i = 0
select @periodo=valor from scl.parametro where parametro='PER_CASCADA'
select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @mes = month(dateadd(mm,-18,@fec_ini))
select @ano = year(dateadd(mm,-18,@fec_ini))
select @periodo,@fec_ini,@mes ,@ano 

while @i <= 19
begin
	select @archivo = right('000'+rtrim(@mes),2)+rtrim(@ano)
	select @query = ' truncate table cascadas.scl.tmp_Cascada_riesgo_Q '+char(13)+char(10)
			   +' insert into cascadas.scl.tmp_Cascada_riesgo_Q '+char(13)+char(10)
		       +' select Mes_Fact='+convert(char(6),@ano*100+@mes)+',  '+char(13)+char(10)
		       +' origen,des_catego, region, tip_client, tip_plan,case when pack is null then 'VOZ' else pack end pack,  '+char(13)+char(10)
		       +' Importe=sum(coalesce(Importe,0)),  '+char(13)+char(10)
		       +' Mes_0= sum(coalesce(Mes_0,0)),  '+char(13)+char(10)
		       +' Rec_0= sum(coalesce(Mes_0,0)),  '+char(13)+char(10)
		       +' Mes_1= sum(coalesce(Mes_1,0)),  '+char(13)+char(10)
		       +' Rec_1= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0)),  '+char(13)+char(10)
		       +' Mes_2= sum(coalesce(Mes_2,0)),  '+char(13)+char(10)
		       +' Rec_2= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0)),  '+char(13)+char(10)
		       +' Mes_3= sum(coalesce(Mes_3,0)),  '+char(13)+char(10)
		       +' Rec_3= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0)),  '+char(13)+char(10)
		       +' Mes_4= sum(coalesce(Mes_4,0)),  '+char(13)+char(10)
		       +' Rec_4= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0))+sum(coalesce(Mes_4,0)),  '+char(13)+char(10)
		       +' Mes_5= sum(coalesce(Mes_5,0)),  '+char(13)+char(10)
		       +' Rec_5= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0))+sum(coalesce(Mes_4,0))+sum(coalesce(Mes_5,0)),  '+char(13)+char(10)
		       +' Mes_6= sum(coalesce(Mes_6,0)),  '+char(13)+char(10)
		       +' Rec_6= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0))+sum(coalesce(Mes_4,0))+sum(coalesce(Mes_5,0))+sum(coalesce(Mes_6,0)),  '+char(13)+char(10)
		       +' Mes_7= sum(coalesce(Mes_7,0)),  '+char(13)+char(10)
		       +' Rec_7= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0))+sum(coalesce(Mes_4,0))+sum(coalesce(Mes_5,0))+sum(coalesce(Mes_6,0))+sum(coalesce(Mes_7,0)),  '+char(13)+char(10)
		       +' Mes_8= sum(coalesce(Mes_8,0)),  '+char(13)+char(10)
		       +' Rec_8= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0))+sum(coalesce(Mes_4,0))+sum(coalesce(Mes_5,0))+sum(coalesce(Mes_6,0))+sum(coalesce(Mes_7,0))+sum(coalesce(Mes_8,0)),  '+char(13)+char(10)
		       +' Mes_9= sum(coalesce(Mes_9,0)),  '+char(13)+char(10)
		       +' Rec_9= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0))+sum(coalesce(Mes_4,0))+sum(coalesce(Mes_5,0))+sum(coalesce(Mes_6,0))+sum(coalesce(Mes_7,0))+sum(coalesce(Mes_8,0))+sum(coalesce(Mes_9,0)),  '+char(13)+char(10)
		       +' Mes_10= sum(coalesce(Mes_10,0)),  '+char(13)+char(10)
		       +' Rec_10= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0))+sum(coalesce(Mes_4,0))+sum(coalesce(Mes_5,0))+sum(coalesce(Mes_6,0))+sum(coalesce(Mes_7,0))+sum(coalesce(Mes_8,0))+sum(coalesce(Mes_9,0))+sum(coalesce(Mes_10,0)),  '+char(13)+char(10)
		       +' Mes_11= sum(coalesce(Mes_11,0)),  '+char(13)+char(10)
		       +' Rec_11= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0))+sum(coalesce(Mes_4,0))+sum(coalesce(Mes_5,0))+sum(coalesce(Mes_6,0))+sum(coalesce(Mes_7,0))+sum(coalesce(Mes_8,0))+sum(coalesce(Mes_9,0))+sum(coalesce(Mes_10,0))+sum(coalesce(Mes_11,0)),  '+char(13)+char(10)
		       +' Mes_12= sum(coalesce(Mes_12,0)),  '+char(13)+char(10)
		       +' Rec_12= sum(coalesce(Mes_0,0))+sum(coalesce(Mes_1,0))+sum(coalesce(Mes_2,0))+sum(coalesce(Mes_3,0))+sum(coalesce(Mes_4,0))+sum(coalesce(Mes_5,0))+sum(coalesce(Mes_6,0))+sum(coalesce(Mes_7,0))+sum(coalesce(Mes_8,0))+sum(coalesce(Mes_9,0))+sum(coalesce(Mes_10,0))+sum(coalesce(Mes_11,0))+sum(coalesce(Mes_12,0)) , '+char(13)+char(10)
		       +' Estado_Cliente,Portabilidad,Familia_Plan, Carterizado,migracion,riesgo '+char(13)+char(10) 	
		       +' from SCL.facturacion_scl_hist '+char(13)+char(10)
			   +' where mes_fact ='+convert(char(6),@ano*100+@mes) + char(13)+char(10)
		       +' and des_catego not in (''ESPECIALES'')  '+char(13)+char(10)
--		       +' and (migracion is null or migracion in (''1'',''H'',''HIBRIDO'',''N'',''NORMAL''))  '+char(13)+char(10)
		       +' and origen in (''SCL'')  '+char(13)+char(10)
		       +' Group by convert(numeric,year(Fec_Emisio)*100+month(Fec_Emisio)), '+char(13)+char(10)
		       +' origen,des_catego, region, tip_client, tip_plan,case when pack is null then ''VOZ'' else pack end, day(fec_emisio),  '+char(13)+char(10)
		       +' Cod_Client, '+char(13)+char(10)
		       +' Estado_Cliente,Portabilidad,Familia_Plan, Carterizado, migracion,riesgo  option(maxdop 1)'+char(13)+char(10) 	

	exec(@query)
	select @mes = @mes + 1
	if (@mes = 13)
	begin 
	select @mes = 1
	select @ano = @ano + 1
	end 
	select @i = @i + 1	
	insert into cascadas.scl.Resumen_Cascada_riesgo_Q
		(Mes_Fact, origen, emp, des_catego, region, tip_client, tip_plan, 
		tip_prod, Tot_Fact, mes_0, Rec_0, mes_1, Rec_1, mes_2, Rec_2, mes_3, Rec_3, 
		mes_4, Rec_4, mes_5, Rec_5, mes_6, Rec_6, mes_7, Rec_7, mes_8, Rec_8, mes_9, 
		Rec_9, mes_10, Rec_10, mes_11, Rec_11, mes_12, Rec_12, Antiguedad, Portabilidad, Familia_Plan, carterizado, migracion, riesgo)
	select Mes_Fact,origen,'' as emp,des_catego, region, tip_client, tip_plan,	tip_prod,
		Tot_Fact=count(*),
		Mes_0= sum(case when Mes_0 > 0 and Rec_0 >= IMPORTE  then 1 else 0 end),
		Rec_0= sum(case when Mes_0 > 0 and Rec_0 >= IMPORTE  then 1 else 0 end),
		Mes_1= sum(case when Mes_1 > 0 and Rec_1 >= IMPORTE  then 1 else 0 end),
		Rec_1= sum(case when Mes_1 > 0 and Rec_1 >= IMPORTE  then 1 else 0 end),
		Mes_2= sum(case when Mes_2 > 0 and Rec_2 >= IMPORTE  then 1 else 0 end),
		Rec_2= sum(case when Mes_2 > 0 and Rec_2 >= IMPORTE  then 1 else 0 end),
		Mes_3= sum(case when Mes_3 > 0 and Rec_3 >= IMPORTE  then 1 else 0 end),
		Rec_3= sum(case when Mes_3 > 0 and Rec_3 >= IMPORTE  then 1 else 0 end),
		Mes_4= sum(case when Mes_4 > 0 and Rec_4 >= IMPORTE  then 1 else 0 end),
		Rec_4= sum(case when Mes_4 > 0 and Rec_4 >= IMPORTE  then 1 else 0 end),
		Mes_5= sum(case when Mes_5 > 0 and Rec_5 >= IMPORTE  then 1 else 0 end),
		Rec_5= sum(case when Mes_5 > 0 and Rec_5 >= IMPORTE  then 1 else 0 end),
		Mes_6= sum(case when Mes_6 > 0 and Rec_6 >= IMPORTE  then 1 else 0 end),
		Rec_6= sum(case when Mes_6 > 0 and Rec_6 >= IMPORTE  then 1 else 0 end),
		Mes_7= sum(case when Mes_7 > 0 and Rec_7 >= IMPORTE  then 1 else 0 end),
		Rec_7= sum(case when Mes_7 > 0 and Rec_7 >= IMPORTE  then 1 else 0 end),
		Mes_8= sum(case when Mes_8 > 0 and Rec_8 >= IMPORTE  then 1 else 0 end),
		Rec_8= sum(case when Mes_8 > 0 and Rec_8 >= IMPORTE  then 1 else 0 end),
		Mes_9= sum(case when Mes_9 > 0 and Rec_9 >= IMPORTE  then 1 else 0 end),
		Rec_9= sum(case when Mes_9 > 0 and Rec_9 >= IMPORTE  then 1 else 0 end),
		Mes_10= sum(case when Mes_10 > 0 and Rec_10 >= IMPORTE  then 1 else 0 end),
		Rec_10= sum(case when Mes_10 > 0 and Rec_10 >= IMPORTE  then 1 else 0 end),
		Mes_11= sum(case when Mes_11 > 0 and Rec_11 >= IMPORTE  then 1 else 0 end),
		Rec_11= sum(case when Mes_11 > 0 and Rec_11 >= IMPORTE  then 1 else 0 end),
		Mes_12= sum(case when Mes_12 > 0 and Rec_12 >= IMPORTE  then 1 else 0 end),
		Rec_12= sum(case when Mes_12 > 0 and Rec_12 >= IMPORTE  then 1 else 0 end),
		antiguedad,Portabilidad,Familia_Plan, Carterizado,migracion,riesgo
		from cascadas.scl.tmp_Cascada_riesgo_Q
		Group by Mes_Fact,origen,des_catego, region, tip_client, tip_plan,tip_prod,
		antiguedad,Portabilidad,Familia_Plan, Carterizado,migracion,riesgo
	
		update cascadas.scl.tmp_Cascada_riesgo_Q set tip_client ='ESPECIAL' where des_catego ='ESPECIAL' and tip_client ='NORMAL'
		update cascadas.scl.tmp_Cascada_riesgo_Q set tip_client ='ESPECIAL' where des_catego ='ESPECIALISTAS' and tip_client ='NORMAL'
		update cascadas.scl.tmp_Cascada_riesgo_Q set tip_client ='ESPECIAL' where des_catego ='RELACIONADA' and tip_client ='NORMAL' option(maxdop 1)
end */

----Resumen Cascada por equipos
set dateformat dmy

truncate table scl.facturacion_equipos
insert into scl.facturacion_equipos 
select * from [servcluprod1\PRDCLINS01].tablas.dbo.facturacion_equipos

--Marcha fechas de pagos
update scl.facturacion_equipos
set mes_pago = b.fec_pago
from scl.facturacion_equipos a inner join scl.facturacion_scl_hist b
on a.cod_tipdocum = b.cod_tipdoc and a.num_folio = b.num_folio
option (maxdop 1)

--OBTIENEN CAUSA DE BAJA
truncate table scl.equipos_fecbaja
insert into scl.equipos_fecbaja
select a.cod_cliente, a.num_ident, a.cod_tipdocum, a.num_folio, a.fec_emision, a.fec_vencimie, a.monto, a.agr_concepto, a.mes_pago,max(convert(char(10),fec_baja,120)) max_fec_baja,null,null
from scl.facturacion_equipos a left join procesos..ga_abocel b
on a.cod_cliente = b.cod_cliente and b.fec_baja < a.fec_emision
group by a.cod_ciclfact, a.cod_cliente, a.num_ident, a.nombre, a.cod_categoria, a.des_categoria, a.cod_tipdocum, a.des_tipdocum, a.num_folio, a.fec_emision, a.fec_vencimie, a.monto, a.agr_concepto, a.castigo, a.mes_castigo, a.mes_pago
option (maxdop 1)

update scl.equipos_fecbaja
set cod_causabaja = b.cod_causabaja
from scl.equipos_fecbaja a left join procesos..ga_abocel b
on a.cod_cliente = b.cod_cliente and a.max_fec_baja = convert(char(10),b.fec_baja,120)
option (maxdop 1)

update scl.equipos_fecbaja
set causa_baja = b.tipo_causabaja
from scl.equipos_fecbaja a inner join inteligencia_cobros..co_causabaja b
on a.cod_causabaja = b.cod_causabaja
option (maxdop 1)

--marca causa en facturacion equipos
update scl.facturacion_equipos
set causa_baja =null
option (maxdop 1)

update scl.facturacion_equipos
set causa_baja = b.causa_baja
from scl.facturacion_equipos a inner join scl.equipos_fecbaja b
on a.cod_tipdocum = b.cod_tipdocum and a.num_folio = b.num_folio
option (maxdop 1)

select @sql=  'Marca Perdida Beneficio'
exec usp_Cascadalog @sql

update a set a.causa_baja='PERDIDA BENEFICIO'
from scl.facturacion_equipos a inner join procesos.dbo.Perdida_Beneficio_ti_facturas b 
on a.cod_cliente=b.cod_cliente  and a.num_folio=b.num_folio

select @sql=  'Resumen Cascada Equipos'
exec usp_Cascadalog @sql


truncate table cascadas.scl.Resumen_Cascada_equipos
select @i = 1
select @periodo =valor from scl.parametro where parametro='PER_CASCADA'
select @fec_ini =dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fec_fin =dateadd(ss,-1,dateadd(mm,1,@fec_ini))
select @mes = month(dateadd(mm,-20,@fec_ini))
select @ano = year(dateadd(mm,-20,@fec_ini))
select @periodo,@fec_ini,@fec_fin,@mes,@ano,@archivo
select @query = ' insert into cascadas.scl.Resumen_Cascada_equipos select  convert(numeric,year(f.Fec_Emisio)*100+month(f.Fec_Emisio)), '+char(13)+char(10)
+' f.origen, f.emp,f.des_catego, f.tip_client, f.tip_plan, case when f.pack is null then ''VOZ'' else f.pack end,sum(f.mto_equipos) as Tot_Fact, day(f.fec_emisio) as dia_emi, '+char(13)+char(10)
+' sum(case when f.mes_0<>0 then f.mto_equipos else 0 end) as mes_0, sum(case when f.mes_0<>0 then f.mto_equipos else 0 end) as Rec_0, '+char(13)+char(10)
+' sum(case when f.mes_1<>0 then f.mto_equipos else 0 end) as mes_1, sum(case when f.mes_1<>0 then f.mto_equipos else 0 end) as Rec_1, '+char(13)+char(10)
+' sum(case when f.mes_2<>0 then f.mto_equipos else 0 end) as mes_2, sum(case when f.mes_2<>0 then f.mto_equipos else 0 end) as Rec_2, '+char(13)+char(10)
+' sum(case when f.mes_3<>0 then f.mto_equipos else 0 end) as mes_3, sum(case when f.mes_3<>0 then f.mto_equipos else 0 end) as Rec_3, '+char(13)+char(10)
+' sum(case when f.mes_4<>0 then f.mto_equipos else 0 end) as mes_4, sum(case when f.mes_4<>0 then f.mto_equipos else 0 end) as Rec_4, '+char(13)+char(10)
+' sum(case when f.mes_5<>0 then f.mto_equipos else 0 end) as mes_5, sum(case when f.mes_5<>0 then f.mto_equipos else 0 end) as Rec_5, '+char(13)+char(10)
+' sum(case when f.mes_6<>0 then f.mto_equipos else 0 end) as mes_6, sum(case when f.mes_6<>0 then f.mto_equipos else 0 end) as Rec_6, '+char(13)+char(10)
+' sum(case when f.mes_7<>0 then f.mto_equipos else 0 end) as mes_7, sum(case when f.mes_7<>0 then f.mto_equipos else 0 end) as Rec_7, '+char(13)+char(10)
+' sum(case when f.mes_8<>0 then f.mto_equipos else 0 end) as mes_8, sum(case when f.mes_8<>0 then f.mto_equipos else 0 end) as Rec_8, '+char(13)+char(10)
+' sum(case when f.mes_9<>0 then f.mto_equipos else 0 end) as mes_9, sum(case when f.mes_9<>0 then f.mto_equipos else 0 end) as Rec_9, '+char(13)+char(10)
+' sum(case when f.mes_10<>0 then f.mto_equipos else 0 end) as mes_10, sum(case when f.mes_10<>0 then f.mto_equipos else 0 end) as Rec_10, '+char(13)+char(10)
+' sum(case when f.mes_11<>0 then f.mto_equipos else 0 end) as mes_11, sum(case when f.mes_11<>0 then f.mto_equipos else 0 end) as Rec_11, '+char(13)+char(10)
+' sum(case when f.mes_12<>0 then f.mto_equipos else 0 end) as mes_12, sum(case when f.mes_12<>0 then f.mto_equipos else 0 end) as Rec_12, '+char(13)+char(10)
+' f.Estado_Cliente,f.Portabilidad,e.agr_concepto,f.Carterizado,f.migracion, rtrim(e.causa_baja) causa_baja '+char(13)+char(10) 	
+' from scl.facturacion_scl_hist f '+char(13)+char(10)
+' inner join scl.facturacion_equipos e on  (e.cod_tipdocum = f.cod_tipdoc and e.num_folio = f.num_folio) and f.cod_tipdoc not in (''52'') '+char(13)+char(10)
+' where f.des_catego not in (''ESPECIALES'') '+char(13)+char(10)
+' and (f.migracion is null or f.migracion in (''1'',''H'',''HIBRIDO'',''N'',''NORMAL'')) '+char(13)+char(10)
+' and f.origen not in (''SAP'') '+char(13)+char(10)
+' Group by  convert(numeric,year(f.Fec_Emisio)*100+month(f.Fec_Emisio)),origen, f.emp,f.des_catego, f.tip_client, f.tip_plan, case when f.pack is null then ''VOZ'' else f.pack end, day(f.fec_emisio), '+char(13)+char(10)
+' f.Estado_Cliente,f.Portabilidad,e.agr_concepto,f.Carterizado,f.migracion,rtrim(e.causa_baja)  OPTION (maxdop 1)'+char(13)+char(10) 	
exec(@query)

select @query = ' insert into cascadas.scl.Resumen_Cascada_equipos select  convert(numeric,year(f.Fec_Emisio)*100+month(f.Fec_Emisio)), '+char(13)+char(10)
+' f.origen, f.emp,f.des_catego, f.tip_client, f.tip_plan, case when f.pack is null then ''VOZ'' else f.pack end,sum(f.mto_equipos) as Tot_Fact, day(f.fec_emisio) as dia_emi, '+char(13)+char(10)
+' sum(case when f.mes_0<>0 then f.mto_equipos else 0 end) as mes_0, sum(case when f.mes_0<>0 then f.mto_equipos else 0 end) as Rec_0, '+char(13)+char(10)
+' sum(case when f.mes_1<>0 then f.mto_equipos else 0 end) as mes_1, sum(case when f.mes_1<>0 then f.mto_equipos else 0 end) as Rec_1, '+char(13)+char(10)
+' sum(case when f.mes_2<>0 then f.mto_equipos else 0 end) as mes_2, sum(case when f.mes_2<>0 then f.mto_equipos else 0 end) as Rec_2, '+char(13)+char(10)
+' sum(case when f.mes_3<>0 then f.mto_equipos else 0 end) as mes_3, sum(case when f.mes_3<>0 then f.mto_equipos else 0 end) as Rec_3, '+char(13)+char(10)
+' sum(case when f.mes_4<>0 then f.mto_equipos else 0 end) as mes_4, sum(case when f.mes_4<>0 then f.mto_equipos else 0 end) as Rec_4, '+char(13)+char(10)
+' sum(case when f.mes_5<>0 then f.mto_equipos else 0 end) as mes_5, sum(case when f.mes_5<>0 then f.mto_equipos else 0 end) as Rec_5, '+char(13)+char(10)
+' sum(case when f.mes_6<>0 then f.mto_equipos else 0 end) as mes_6, sum(case when f.mes_6<>0 then f.mto_equipos else 0 end) as Rec_6, '+char(13)+char(10)
+' sum(case when f.mes_7<>0 then f.mto_equipos else 0 end) as mes_7, sum(case when f.mes_7<>0 then f.mto_equipos else 0 end) as Rec_7, '+char(13)+char(10)
+' sum(case when f.mes_8<>0 then f.mto_equipos else 0 end) as mes_8, sum(case when f.mes_8<>0 then f.mto_equipos else 0 end) as Rec_8, '+char(13)+char(10)
+' sum(case when f.mes_9<>0 then f.mto_equipos else 0 end) as mes_9, sum(case when f.mes_9<>0 then f.mto_equipos else 0 end) as Rec_9, '+char(13)+char(10)
+' sum(case when f.mes_10<>0 then f.mto_equipos else 0 end) as mes_10, sum(case when f.mes_10<>0 then f.mto_equipos else 0 end) as Rec_10, '+char(13)+char(10)
+' sum(case when f.mes_11<>0 then f.mto_equipos else 0 end) as mes_11, sum(case when f.mes_11<>0 then f.mto_equipos else 0 end) as Rec_11, '+char(13)+char(10)
+' sum(case when f.mes_12<>0 then f.mto_equipos else 0 end) as mes_12, sum(case when f.mes_12<>0 then f.mto_equipos else 0 end) as Rec_12, '+char(13)+char(10)
+' f.Estado_Cliente,f.Portabilidad,''CUOTA INICIAL'',f.Carterizado,f.migracion, ''Cuota Inicial'' '+char(13)+char(10) 	
+' from scl.facturacion_scl_hist f  '+char(13)+char(10)
+' where f.cod_tipdoc = ''52'' and f.des_catego not in (''ESPECIALES'') '+char(13)+char(10)
+' and (f.migracion is null or f.migracion in (''1'',''H'',''HIBRIDO'',''N'',''NORMAL'')) '+char(13)+char(10)
+' and f.origen not in (''SAP'') and year(f.Fec_Emisio)*100+month(f.Fec_Emisio) in (201303,201304) '+char(13)+char(10)
+' Group by  convert(numeric,year(f.Fec_Emisio)*100+month(f.Fec_Emisio)),origen, f.emp,f.des_catego, f.tip_client, f.tip_plan, case when f.pack is null then ''VOZ'' else f.pack end, day(f.fec_emisio), '+char(13)+char(10)
+' f.Estado_Cliente,f.Portabilidad,f.Carterizado,f.migracion OPTION (maxdop 1)'+char(13)+char(10) 	
exec(@query)

update scl.facturacion_equipos set causa_baja ='CUOTA INICIAL' where causa_baja ='Cuota Inicial'

update cascadas.scl.Resumen_Cascada_equipos 
set causa_baja = 'VIGENTE' where causa_baja is null

update scl.parametro set valor =substring((convert(char(6),year(getdate())*100+month(getdate()))),5,2)+substring((convert(char(6),year(getdate())*100+month(getdate()))),1,4)
end

select @sql=  'Cascadas por region diaria'
exec usp_Cascadalog @sql

exec usp_cascada_region_dia