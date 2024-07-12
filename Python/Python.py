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