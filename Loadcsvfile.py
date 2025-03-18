import pandas as pd
from sqlalchemy import create_engine

# Step 1: Load the dataset
df = pd.read_csv("/Users/maaz/Documents/Data/data.csv")  # Replace with the path to your CSV file

# Step 2: Convert InvoiceDate to datetime
df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"])

# Step 3: Create a MySQL engine for connecting
from sqlalchemy import create_engine
import getpass

password = getpass.getpass("Enter MySQL password: ")
engine = create_engine(f"mysql+pymysql://root:{password}@localhost/ecommerce")


  # Replace 'password' with your MySQL root password

# Step 4: Insert the data into the MySQL database
df.to_sql("transactions", con=engine, if_exists="append", index=False)

print("Data imported successfully!")
