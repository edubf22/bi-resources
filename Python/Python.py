# Capacity plot (error bar) 
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Assuming dataset is already defined and loaded
fe_data = dataset['Value'].dropna()

# Calculate mean and standard deviation of fe_data
mean = np.mean(fe_data)
std_dev = np.std(fe_data, ddof=1)

# Calculate AverageValue and StdDevValue similar to DAX logic
AverageValue = fe_data.mean()
StdDevValue = fe_data.std(ddof=0)  # Population standard deviation

# Filter data as per DAX logic
FilteredTable = fe_data[abs(fe_data - AverageValue) <= 1.3 * StdDevValue]

# Calculate Std Dev Within FilteredTable
StdDevWithin = FilteredTable.std(ddof=0)  # Population standard deviation

# Define graph limits
limit_max = dataset['.USL']
x_max = max(limit_max)
limit_min = dataset['.LSL']
x_min = max(limit_min)

# Create the figure and axis
fig, ax = plt.subplots(figsize=(8, 7))

# Plot the error bar graphs
ax.errorbar(mean, 1, xerr=std_dev, fmt='x', color='blue', ms=20, ecolor='red', elinewidth=3, capsize=15, label='Overall')
ax.errorbar(mean, -1, xerr=StdDevWithin, fmt='x', color='blue', ms=20, ecolor='red', elinewidth=3, capsize=15, label='Within')
ax.errorbar(mean, -3, xerr=[[mean - x_min], [x_max - mean]], color='blue', ms=20, ecolor='red', elinewidth=3, capsize=15)

# Add labels and title
ax.set_title('Capability plot', fontsize=20)
ax.grid(False)

# Set x-axis limits
ax.set_xlim(x_min-0.005*x_min, x_max+0.005*x_max)

# Customize the y-axis to remove unnecessary space
ax.set_ylim(-4, 2)
ax.set_yticks([-3, -1, 1])
ax.set_yticklabels(['Specs', 'Within', 'Overall'], fontsize = 15)

# Show the plot
plt.show() 

############################################################################################

# Send an XML POST Request to Sage Intacct API
import requests
from datetime import datetime
import uuid

# Define your variables
url = 'your_url'
sender_id = 'your_sender_id'
sender_password = 'your_sender_password'
user_id = 'your_user_id'
company_id = 'your_company_id'
temp_slide_in = 'your_temp_slide_in' # Optional, leave as empty string if not used
user_password = 'your_user_password'

# Prepare your XML data
data = f'''<?xml version="1.0" encoding="UTF-8"?>
<request>
  <control>
    <senderid>{sender_id}</senderid>
    <password>{sender_password}</password>
    <controlid>{datetime.now().isoformat()}</controlid>
    <uniqueid>false</uniqueid>
    <dtdversion>3.0</dtdversion>
    <includewhitespace>false</includewhitespace>
  </control>
  <operation>
    <authentication>
      <login>
        <userid>{user_id}</userid>
        <companyid>{company_id}{temp_slide_in}</companyid>
        <password>{user_password}</password>
      </login>
    </authentication>
    <content>
      <function controlid="{str(uuid.uuid4())}">
        <getAPISession />
      </function>
    </content>
  </operation>
</request>'''

# Define your headers
headers = {'Content-Type': 'application/xml'}  # or whatever your server accepts

# Send the POST request
response = requests.post(url, headers=headers, data=data)

# Print the response
print(response.text)

# Parse XML data using ElementTree
import xml.etree.ElementTree as ET

root = ET.fromstring(response.content)

# Navigate the XML tree
for child in root:
    print(child.tag, child.attrib)

# Iterate over elements in a list
[elem.tag for elem in root.iter()]

# Find the sessionid element
sessionid_element = root.find(".//sessionid")

# Get the sessionid value
sessionid = sessionid_element.text
print(sessionid)

# Split a string 
filename = "example_file.txt"
filename_split = filename.split("_") # Split the filename by underscore, or the type by using "." as the delimiter"