USE [Cascadas]
GO
/****** Object:  StoredProcedure [SCL].[usp_scl_Cscda_03_Marcas]    Script Date: 07/12/2016 11:05:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER procedure [SCL].[usp_scl_Cscda_03_Marcas]
as
begin

set dateformat dmy
declare @fec_ini datetime, @fec_fin datetime,@fecha datetime
declare @query nvarchar(4000), @sql nvarchar(4000),@fecha2 nvarchar(6)
declare @periodo char(6)
declare @i int, @ano numeric
declare @archivo char(20),@mes numeric,@mes2 numeric

--**************************************************************************************
select @sql=  'Insertar Cuotas en Facturacion'
--**************************************************************************************
exec usp_Cascadalog @sql

select @i = 0
select @periodo=valor from scl.parametro where parametro='PER_CASCADA'
select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
select @fecha=dateadd(mm,-12,@fec_ini) 
select @mes = month(dateadd(mm,0,@fec_ini))
select @ano = year(dateadd(mm,0,@fec_ini))
select @archivo = right('000'+rtrim(@mes),2)+rtrim(@ano)
select @periodo,@fec_ini,@fecha,@mes,@ano,@archivo

	select @query = ' insert into scl.fact_'+@archivo+char(13)+char(10)
		       +' (origen,emp,num_ident,nom_client,cod_client, '+char(13)+char(10)
		       +' cliente,cuenta,cod_tipdoc,num_folio,fec_emisio,  '+char(13)+char(10)
		       +' fec_vencim,importe,des_catego,llave,excluir,migracion,  '+char(13)+char(10)
		       +' tip_plan,tip_client,tip_prod,tramo,fec_pago,num_cuota,sec_cuota) '+char(13)+char(10)
		       +' select origen,emp,num_ident,nom_client,cod_client, '+char(13)+char(10)
		       +' cliente,cuenta,cod_tipdoc,num_folio,fec_emisio, '+char(13)+char(10)
		       +' fec_vencim,importe,des_catego,llave,excluir,migracion, '+char(13)+char(10)
		       +' tip_plan,tip_client,tip_prod,tramo,fec_pago,num_cuota,sec_cuota  '+char(13)+char(10)
		       +' from scl.co_cancel_Cuota  '+char(13)+char(10)
		       +' where origen is not null and  '+char(13)+char(10)
		       +' right(''0000''+rtrim(month(fec_emisio)),2)+rtrim(year(fec_emisio)) = '+@archivo+char(13)+char(10)
	exec(@query)


--**************************************************************************************
select @sql=  'Marca Cartera Especial por RUt'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query='update scl.Fact_'+rtrim(@periodo)+char(13)+char(10)
+'set des_catego = b.des_categoria, '+char(13)+char(10)
+'	nom_client = case '+char(13)+char(10)
+' when a.num_ident=''6-K'' then a.nom_client '+char(13)+char(10)
+' else b.nom_cliente '+char(13)+char(10)
+' end, '+ char(13)+char(10)
+' tip_client=''ESPECIAL'' '+ char(13)+char(10)
+' from scl.Fact_'+ rtrim(@periodo) +' a inner join (select cod_ident, origen = nom_origen, rut, nom_cliente = upper(max(nom_cliente)), '+char(13)+char(10)
+' des_categoria = upper(nom_entidad), cod_gestion '+char(13)+char(10)
+' from (scl.cta_cespecial a '+char(13)+char(10)
+' inner join scl.cta_origen b on a.cod_origen =b.cod_origen) '+char(13)+char(10)
+' inner join scl.cta_entidad c on a.cod_entidad =c.cod_entidad '+char(13)+char(10)
+' where cod_ident=1 '+char(13)+char(10)
+' group by cod_ident, nom_origen, rut, nom_entidad, cod_gestion) b '+char(13)+char(10)
+' on a.origen collate Modern_Spanish_CI_AS =b.origen and a.num_ident collate Modern_Spanish_CI_AS =b.rut '+char(13)+char(10)
+' where a.des_catego<>''MOVIL PACK'' option (maxdop 1)'

exec(@query)


--**************************************************************************************
select @sql=  'Marca Cartera Especial por Codigo'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query='update scl.Fact_'+rtrim(@periodo)+char(13)+char(10)
+'set des_catego =b.des_categoria, nom_client =b.nom_cliente, tip_client=''ESPECIAL'' '+char(13)+char(10)
+'from scl.Fact_'+ rtrim(@periodo) +' a inner join ( '+char(13)+char(10)
+'		select cod_ident, origen=nom_origen, cod_cliente, nom_cliente=upper(nom_cliente), '+char(13)+char(10)
+'			des_categoria=upper(nom_entidad), cod_gestion '+char(13)+char(10)
+'		from (scl.cta_cespecial a '+char(13)+char(10)
+'			inner join scl.cta_origen b on a.cod_origen =b.cod_origen) '+char(13)+char(10)
+'			inner join scl.cta_entidad c on a.cod_entidad=c.cod_entidad '+char(13)+char(10)
+'		where cod_ident=2 or rut=''6-K'' '+char(13)+char(10)
+'		group by cod_ident, nom_origen, cod_cliente, nom_cliente, nom_entidad, cod_gestion) b '+char(13)+char(10)
+'	on a.origen collate Modern_Spanish_CI_AS =b.origen and a.cod_client = b.cod_cliente '+char(13)+char(10)
+' where a.des_catego<>''MOVIL PACK'' option (maxdop 1)'

exec (@query)


--**************************************************************************************
select @sql=  'Marca Migrados < a 180' 
--**************************************************************************************
exec usp_Cascadalog @sql
select @query= 'update scl.Fact_'+rtrim(@periodo)+char(13)+char(10)
		+'set tip_client=case'+char(13)+char(10)
		+'		when not b.cod_cliente is null then ''MIGR. 180'' '+char(13)+char(10)
		+'		else a.tip_client'+char(13)+char(10)	
		+'		end '+char(13)+char(10)
		+'from scl.Fact_'+rtrim(@periodo)+' a inner join' +char(13)+char(10)
		+'[servcluprod1\PRDCLINS01].ctacte.dbo.migrados_cod  b'+char(13)+char(10)
		+'on a.cod_client=b.cod_cliente and datediff(d,b.fec_migracion,a.fec_emisio)<=180 '+ char(13)+char(10)
		+'where a.origen=''SCL'' '+char(13)+char(10)
		+'and a.des_catego in (''PERSONAS'',''GRANDES'',''MEDIANAS'',''MICRO'',''PEQUEÑAS'',''AUTONOMOS'') option(maxdop 1)'
exec (@query)
--**************************************************************************************
select @sql=  'Marca Migrados > a 180' 
--**************************************************************************************
exec usp_Cascadalog @sql
select @query= 'update scl.Fact_'+rtrim(@periodo)+char(13)+char(10)
		+'set tip_client=case'+char(13)+char(10)
		+'		when not b.cod_cliente is null then ''MIGR. 360'' '+char(13)+char(10)
		+'		else a.tip_client'+char(13)+char(10)	
		+'		end '+char(13)+char(10)
		+'from scl.Fact_'+rtrim(@periodo)+' a inner join' +char(13)+char(10)
		+'[servcluprod1\PRDCLINS01].ctacte.dbo.migrados_cod  b'+char(13)+char(10)
		+'on a.cod_client=b.cod_cliente and datediff(d,b.fec_migracion,a.fec_emisio)>180 '+ char(13)+char(10)
		+'where a.origen=''SCL'' '+char(13)+char(10)
		+'and a.des_catego in (''PERSONAS'',''GRANDES'',''MEDIANAS'',''MICRO'',''PEQUEÑAS'',''AUTONOMOS'') option(maxdop 1)'
exec (@query)



--**************************************************************************************
select @sql=  'Marca Movilpack'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query= 'update scl.Fact_'+rtrim(@periodo)+char(13)+char(10)
		+'set tip_client=''MOVILPACK'' '+char(13)+char(10)
		+'from scl.Fact_'+rtrim(@periodo)+char(13)+char(10)
		+'where des_catego=''MOVIL PACK'' option(maxdop 1)'

exec (@query)


--**************************************************************************************
select @sql=  'Marca Hibrido'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query= 'update scl.Fact_'+ rtrim(@periodo) +char(13)+char(10)
		+'set tip_plan=''HIBRIDO'' '+char(13)+char(10)
		+'from scl.Fact_'+rtrim(@periodo)+' a inner join '+char(13)+char(10)
		+'(select cod_cliente from scl.cta_hibridos group by cod_cliente) b'+char(13)+char(10)
		+'on a.cod_client=b.cod_cliente'+char(13)+char(10)
		+'and origen=''SCL'' option(maxdop 1)'
exec (@query)


--**************************************************************************************
select @sql=  'Marca Producto'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query= 'update scl.Fact_'+ rtrim(@periodo) +char(13)+char(10)
		+' set tip_prod= '+char(13)+char(10)
		+' case when fact.origen in (''SCL'') and fact.cod_client = bam.cod_client then ''Datos'' '+char(13)+char(10)
		+' else ''Normal'' end '+char(13)+char(10)
		+' from scl.Fact_'+rtrim(@periodo)+' fact left join '+char(13)+char(10)
		+' (select rtrim(str(cod_cliente)) as cod_client from scl.cb_bam group by rtrim(str(cod_cliente))) bam'+char(13)+char(10)
		+' on fact.cod_client = bam.cod_client option(maxdop 1)'
exec (@query)


--**************************************************************************************
select @sql=  'Marca Tramo'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query= 'update scl.Fact_'+ rtrim(@periodo) +char(13)+char(10)
		+' set tramo_monto= case when importe <= 10000  then ''1_10.000''' +char(13)+char(10)
		+' when importe between 10001  and 20000  then '' 10.001_20.000''' +char(13)+char(10)
		+' when importe between 20001  and 30000  then '' 20.001_30.000''' +char(13)+char(10)
		+' when importe between 30001  and 50000  then '' 30.001_50.000''' +char(13)+char(10)
		+' when importe between 50001  and 100000 then '' 50.001_100.000'''+char(13)+char(10)
		+' when importe between 100001 and 200000 then ''100.001_200.000'''+char(13)+char(10)
		+' when importe between 200001 and 500000 then ''200.001_500.000'''+char(13)+char(10)
		+' when importe > 500000 then ''MAS_500.000'' end option(maxdop 1)'+char(13)+char(10)
exec (@query)

/*--**************************************************************************************
select @sql=  'Marca Region'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query= 'update scl.Fact_'+ rtrim(@periodo) +char(13)+char(10)
		+' set Region= bam.Cod_Region'+char(13)+char(10)
		+' from scl.Fact_'+rtrim(@periodo)+' fact left join '+char(13)+char(10)
		+' (select Origen+rtrim(cod_cliente) as cod,Cod_region from procesos..ge_clientes group by Origen+rtrim(cod_cliente),cod_region) bam'+char(13)+char(10)
		+' on fact.Origen+rtrim(fact.cod_client) = bam.cod '
exec (@query)
*/
--**************************************************************************************
select @sql=  'Marca Planes'
--**************************************************************************************
exec usp_Cascadalog @sql

select @mes2 = dbo.fn_finmes(left(@periodo,2))
select @fec_fin=convert(datetime,right(@periodo,4)+left(@periodo,2)+rtrim(@mes2))

truncate table scl.ga_abocel_plan
	
select @query = ' insert into scl.ga_abocel_plan '+char(13)+char(10)
				+' select Periodo ='''+@periodo+''',cod_cliente, '+char(13)+char(10)
				+' fec_baja=max(fec_baja),fec_alta=min(fec_alta), '+char(13)+char(10)
				+' BAM=max(case when a.cod_plantarif collate Modern_Spanish_CI_AS = b.cod_plantarif then 1 else 0 end), '+char(13)+char(10)
				+' VOZ =max(case when b.des_plantarif is null then 1 else 0 end) '+char(13)+char(10)
				+' from procesos..ga_abocel a left join '+char(13)+char(10)
				+' scl.bm_plan_bam b '+char(13)+char(10)
				+' on a.cod_plantarif collate Modern_Spanish_CI_AS = b.cod_plantarif '+char(13)+char(10)
				+' where fec_baja>'''+rtrim(convert(char,@fec_fin,105))+''' or  '+char(13)+char(10)
				+' (fec_baja is null and fec_alta <='''+rtrim(convert(char,@fec_fin,105))+''') '+char(13)+char(10)
				+' group by cod_cliente  option(maxdop 1)'+char(13)+char(10)
exec(@query)

	select @query =  ' update b set  b.BAM=a.BAM,b.VOZ=a.VOZ, '+char(13)+char(10) 
					+' pack=case when a.BAM=1 and a.VOZ=0 then ''BAM'' '+char(13)+char(10) 
					+' when a.BAM=1 and a.VOZ=1 then ''BAM+VOZ'' else ''VOZ'' end, '+char(13)+char(10) 
					+' Estado_Cliente= case when datediff(mm,a.fec_alta,fec_emisio) <= 6  '+char(13)+char(10)
					+' then ''NUEVO'' end '+char(13)+char(10)
					+' From scl.ga_abocel_plan a '+char(13)+char(10)
					+' inner join scl.fact_'+@periodo+' b '+char(13)+char(10)
					+' on a.cod_cliente = b.cod_client '+char(13)+char(10)
					+' where periodo collate Modern_Spanish_CI_AS = '''+@periodo+''' option(maxdop 1)'

	exec(@query)


--**************************************************************************************
select @sql= ' Generando Tabla Familia Plan '
--**************************************************************************************
exec usp_Cascadalog @sql

	select @i = 0
	select @periodo=valor from scl.parametro where parametro='PER_CASCADA'
	select @fec_ini=dateadd(mm,@i ,right(@periodo,4)+left(@periodo,2)+'01')
--	select @fec_ini=dateadd(mm,@i ,'20120301')
	select @fec_fin=dateadd(ss,-1,dateadd(mm,1,@fec_ini))
	select @mes = month(dateadd(mm,@i,@fec_ini))
	select @ano = year(dateadd(mm,@i,@fec_ini))

	select @archivo = right('000'+rtrim(@mes),2)+rtrim(@ano)
	select @fecha = dateadd(mm,1,rtrim(@ano)+right('000'+rtrim(@mes),2)+'01')

truncate table scl.Familia_Plan
Insert into scl.Familia_Plan
select @periodo,Cod_Cliente,cod_plantarif,Familia_Plan,
Fec_Baja=max(Fec_Baja),Fec_Alta=Min(Fec_Alta)
from procesos..ga_abocel a inner join 
		(select codigo_plan,
		retencion=tipo_plan,
		familia_plan = CLASIFICACION_final
		from scl.Planes_Movil) b
on a.cod_plantarif collate Modern_Spanish_CI_AS = b.codigo_plan
		Group by Cod_Cliente,cod_plantarif,Familia_Plan
having (max(Fec_Baja) >= @fecha or max(Fec_Baja) is null)
and Min(Fec_Alta) < @fecha option(maxdop 1)


--**************************************************************************************
select @sql= ' Incorporando Familia Plan en la facturacion'
--**************************************************************************************
exec usp_Cascadalog @sql


	select @sql=  ' Resumen '+rtrim(@archivo)
	exec usp_Cascadalog @sql

	select @query = ' update a set a.cod_plantarif = b.cod_plantarif,'+char(13)+char(10)
		       +' a.Familia_Plan = b.Familia_Plan '+char(13)+char(10)
		       +' from scl.fact_'+@archivo+' a inner join scl.Familia_Plan b '+char(13)+char(10)
		       +' on a.cod_client = b.cod_cliente option(maxdop 1) '+char(13)+char(10)
	exec (@query)

----**************************************************************************************
--select @sql= ' Marca Carterizados'
----**************************************************************************************
--	select @query = ' update a set Carterizado = ''SI''  '+char(13)+char(10) 	
--		       +' from scl.fact_'+@archivo+' a inner join scl.tmp_rut_negocios_carterizados b '+char(13)+char(10)
--		       +' on a.num_ident = b.num_ident collate database_Default'+char(13)+char(10)
--		       +' where des_catego in (''NEGOCIOS'',''PYMES'') '+char(13)+char(10)
--		       +' and (migracion is null or migracion in (''H'',''HIBRIDO'',''N'',''NORMAL'')) '+char(13)+char(10)
--		       +' and origen not in (''SAP'') option(maxdop 1) '+char(13)+char(10)
--	exec(@query)

--**************************************************************************************
select @sql= ' Marca Portados IN y OUT'
--**************************************************************************************
exec usp_Cascadalog @sql
	select @query = ' update a set Portabilidad = ''PORT OUT''  '+char(13)+char(10) 	
		       +' from scl.fact_'+@archivo+' a inner join inteligencia_cobros..portabilidad b '+char(13)+char(10)
		       +' on a.cod_client = convert(numeric,b.cliente_movil) and b.Desc_emp_D =''TELEFONICA MOVIL'' option(maxdop 1) '+char(13)+char(10)
	exec(@query)

	select @query = ' update a set Portabilidad = ''PORT IN''  '+char(13)+char(10) 	
		       +' from scl.fact_'+@archivo+' a inner join inteligencia_cobros..portabilidad  b '+char(13)+char(10)
		       +' on a.cod_client = convert(numeric,b.cliente_movil) and Desc_emp_R = ''TELEFONICA MOVIL'' option(maxdop 1) '+char(13)+char(10)
	exec(@query)


--**************************************************************************************
select @sql= 'Marca Migrados entre 1 y 2 años'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query = ' update a set migracion =''1'' from scl.fact_'+@archivo+' a inner join [servcluprod1\PRDCLINS01].ctacte.dbo.exmigrados_cod b 
on a.cod_client=b.cod_cliente and a.fec_emisio between dateadd(yy,1,b.fec_migracion) and dateadd(yy,2,b.fec_migracion) 
where a.tip_client =''NORMAL'' and a.des_catego in (''PERSONAS'',''GRANDES'',''MEDIANAS'',''MICRO'',''PEQUEÑAS'',''AUTONOMOS'') option(maxdop 1) '
exec(@query)

--**************************************************************************************
select @sql= 'Actualiza Monto equipos'
--**************************************************************************************
exec usp_Cascadalog @sql
select @query = 'alter table scl.fact_'+@archivo+' add monto_equipos numeric, cod_ciclo int'
exec(@query)

select @query = 'update a set monto_equipos = b.monto from scl.fact_'+@archivo+' a 
inner join [servcluprod1\PRDCLINS01].tablas.dbo.facturacion_equipos b 
on a.cod_client = b.cod_cliente and a.cod_tipdoc = b.cod_tipdocum and a.num_folio = b.num_folio option(maxdop 1)'
exec(@query)

--**************************************************************************************
select @sql= ' Actualiza Codigo Ciclo'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query = ' update a set cod_ciclo = b.cod_ciclo  '+char(13)+char(10) 	
	       +' from scl.fact_'+@archivo+' a inner join procesos..ge_clientes b '+char(13)+char(10)
	       +' on a.cod_client = b.cod_cliente option(maxdop 1) '+char(13)+char(10)
exec(@query)


select @sql= ' Actualiza Marca 4G'

select @query = ' update scl.fact_'+@archivo+' set pack=''PLAN 4G''
where cod_client in (
		select b.cod_cliente from bajas.movil.ta_plantarif a 
		inner join bajas.movil.clientes b on a.cod_plantarif=b.cod_plantarif collate database_default
		WHERE a.des_plantarif like ''%4G%''group by b.cod_cliente)'

exec(@query)

select @sql= ' Actualiza Marca Region'

select @query = ' update a set a.region=b.cod_region
from scl.fact_'+@archivo+' a inner join (
select cod_cliente,cod_region from cobranza.dbo.ge_direcciones
group by cod_cliente,cod_region) b on a.cod_client=b.cod_cliente'

exec(@query)

--**************************************************************************************
select @sql= ' INCORPORAR A SCL HISTORICO'
--**************************************************************************************
exec usp_Cascadalog @sql

select @query = ' insert into SCL.FACTURACION_SCL_HIST (mes_fact, origen, emp, num_ident, nom_client, cod_client, cliente, cuenta, cod_tipdoc, num_folio, fec_emisio, fec_vencim, importe, des_catego, mes_0, mes_1, mes_2, mes_3, mes_4, mes_5, mes_6, mes_7, mes_8, mes_9, mes_10, mes_11, mes_12, llave, excluir, migracion, tip_plan, tip_client, tip_prod, tramo, tramo_monto, region, fec_pago, num_cuota, sec_cuota, Cant_Abonados, BAM, VOZ, Pack, Estado_Cliente, Portabilidad, Valor, Cod_Plantarif, Familia_Plan, carterizado, mto_equipos,cod_ciclo) 
select '+convert(char(6),@ano*100+@mes) + ', origen, emp, num_ident, nom_client, cod_client, cliente, cuenta, cod_tipdoc, num_folio, fec_emisio, fec_vencim, importe, des_catego, mes_0, mes_1, mes_2, mes_3, mes_4, mes_5, mes_6, mes_7, mes_8, mes_9, mes_10, mes_11, mes_12, llave, excluir, migracion, tip_plan, tip_client, tip_prod, tramo, tramo_monto, region, fec_pago, num_cuota, sec_cuota, Cant_Abonados, BAM, VOZ, Pack, Estado_Cliente, Portabilidad, Valor, Cod_Plantarif, Familia_Plan, carterizado, monto_equipos,cod_ciclo 
from scl.fact_'+@archivo +' option(maxdop 1)'
exec(@query)

end