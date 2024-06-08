
from sqlalchemy import create_engine, URL
import pandas as pd



try:
    connection_url = URL.create(
    "mssql+pyodbc",
    host=".\\SQLEXPRESS",
    database= "SQLCaseStudy",
    query={
        "driver": "ODBC Driver 17 for SQL Server"
    }
)
    engine = create_engine(connection_url)
    
    youtube_csv = "top-5000-youtube-channels.csv"
    dfp = pd.read_csv(youtube_csv)
    dfp.to_sql("youtube5000", con=engine, if_exists='replace', index=False)
    

except Exception as e:
    print("An error occurred:")
    print(e)





"""Connection engine from the docs"""
# from sqlalchemy.engine import URL
# connection_url = URL.create(
#     "mssql+pyodbc",
#     username="scott",
#     password="tiger",
#     host="mssql2017",
#     port=1433,
#     database="test",
#     query={
#         "driver": "ODBC Driver 18 for SQL Server",
#         "TrustServerCertificate": "yes",
#         "authentication": "ActiveDirectoryIntegrated",
#     },
# )

"""Driver"""
# Know your driver from ODBC Data Sources 