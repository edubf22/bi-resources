# Select from a lakehouse table and write to a temporary view
DeltaTableName = "<DeltaTableName>"

df = spark.sql(f"""SELECT * FROM <LakehouseName>.{DeltaTableName}""")
df.createOrReplaceTempView("<TempViewName>")

df_formatted = spark.sql(f"""
    SELECT 
        <SourceTableField1>                     -- DestinationTableField name matches SourceTableField name
        ,NULL AS <DestinationTableField>        -- Field is missing from SourceTable
        ,<SourceTableField2>                    -- Another matching field, such as 'Year'
        current_timestamp() AS CreatedOn,       -- CreatedOn for control by using a function
    FROM <TempViewName>
""")

# Get the target table
target_table = DeltaTable.forName(spark, "<LakehouseName>.<DestinationTableName>")
    
# Merge Data to Silver Layer
target_table.alias("Target")\
    .merge(
        df_formatted.alias("Source"),
        f"""Target.<MergeKey1> = Source.<MergeKey1> AND Target.<MergeKey2> = Source.<MergeKey2>""")\
    .whenMatchedUpdateAll().whenNotMatchedInsertAll().execute()

# Drop Temp Table
spark.catalog.dropTempView("<TempViewName>")

# Rename a column 
df = df.withColumnRenamed("OriginalName", "NewName")
display(df)