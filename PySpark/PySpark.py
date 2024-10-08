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

# List the tables in the lakehouse
spark.catalog.listTables("<LakehouseName>")

# Check for duplicates v1
"""
First group by all columns and count, then show duplicate rows
"""
from pyspark.sql.functions import col

df_duplicates = df.groupBy(df.columns).count().filter(col("count") > 1)
df_duplicates.show()

# Check for duplicates v2
""" 
Find duplicate rows, then show them
"""
df_duplicates = df.exceptAll(df.dropDuplicates())
df_duplicates.show()

# List all files in a directory and store the name of the latest file
import os

def get_latest_file(directory):
    """
    Input: directory path
    Output: filename for the most recent file in the directory
    """
    files = os.listdir(directory)
    
    # Initialize variables to track the latest file and its timestamp
    latest_file = ""
    latest_timestamp = 0
    
    # Iterate through all files to find the one with the latest timestamp
    for file in files:
        file_path = os.path.join(directory, file)
        file_timestamp = os.path.getctime(file_path)
        
        if file_timestamp > latest_timestamp:
            latest_timestamp = file_timestamp
            latest_file = file
    
    return latest_file

# Join directory and filename
file_path = os.path.join("<directory path>", "<filename>")

# Load JSON into a DataFrame
df = spark.read.option("multiline", "false").json(file_path) # check if file is multiline or not, false by default

# List all files in a folder
"""
First define target folder, then list all files in the folder using os library, then print the names of the files
"""
import os

root_folder = "/lakehouse/default/Files" # Define root folder

files = [] # List all of the files in the root folder

for file in os.listdir(root_folder): # Iterate through all files in the root folder and append to the list
    if os.path.isfile(os.path.join(root_folder, file)):
        files.append(file)
    else:
        pass

for file in files: # Print the names of the files
    print(file)

# Move files from one folder to another
"""
This example shows how to move files from a folder to a new subfolder based on the current date
"""
import os
from datetime import datetime
import shutil

root_folder = "/lakehouse/default/Files" # Define root and subfolder paths
subfolder = "/lakehouse/default/Files/purefacts"

current_date = datetime.now().strftime("%Y%m%d") # Get current date to name target folder
target_folder = os.path.join(subfolder, current_date)

os.makedirs(target_folder, exist_ok=True) # Create target folder if it doesn't exist

files = [f for f in os.listdir(root_folder) if os.path.isfile(os.path.join(root_folder, f))] # List all files in the root folder

for file in files: # Move each file to the target folder
    source_path = os.path.join(root_folder, file)
    target_path = os.path.join(target_folder, file)
    shutil.move(source_path, target_path)

print(f"Moved {len(files)} files to {target_folder}") # Print the status of the move operation

# Try-except block
try:
    # Append the DataFrame to the existing lakehouse table
    df.write.format("delta").mode("append").saveAsTable("<tablename>")
    print("Data merged successfully")
except Exception as e:
    print(f"An error occurred while merging data: {e}")
