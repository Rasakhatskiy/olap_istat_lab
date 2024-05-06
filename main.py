import csv
import psycopg2
from tkinter import *
from tkinter import ttk

conn = psycopg2.connect(
    dbname="postgres",
    user="postgres",
    password="password",
    host="192.168.110.136",
    port="5432"
)
# conn.set_client_encoding('UNICODE')
cursor = conn.cursor()


def insert_from_csv(csv_file, table_name):

    query = f"DELETE FROM {table_name};"
    cursor.execute(query)

    # Open CSV file
    with open(csv_file, 'r', encoding='utf-8') as file:
        reader = csv.reader(file)
        next(reader)  # Skip header row
        
        # Iterate through CSV rows and insert into PostgreSQL table
        for row in reader:
            placeholders = ', '.join(['%s'] * len(row))

            query = f"INSERT INTO {table_name} VALUES ({placeholders})"
            cursor.execute(query, row)

    # Commit changes and close connections
    conn.commit()


def clear_table(table_name):
    query = f"DELETE FROM {table_name};"
    cursor.execute(query)
    conn.commit()


def populate_db():
    clear_table('crime_case_person')
    clear_table('crime_case')
    clear_table('crime_type')
    clear_table('location')
    clear_table('detective')
    clear_table('policeman')
    clear_table('person')
    clear_table('police_department')
    clear_table('crime_type')

    insert_from_csv('crime_type.csv', 'crime_type')
    insert_from_csv('police_department.csv', 'police_department')
    insert_from_csv('person.csv', 'person')
    insert_from_csv('policeman.csv', 'policeman')
    insert_from_csv('detective.csv', 'detective')
    insert_from_csv('location.csv', 'location')
    insert_from_csv('case.csv', 'crime_case')
    insert_from_csv('sus_criminal.csv', 'crime_case_person')


if __name__ == '__main__':
    populate_db()

    # root = Tk()
    # frm = ttk.Frame(root, padding=10)
    # frm.grid()
    #
    # # add buttons "Edit data", "Save", "Slice", "Diagrams", "About"
    # ttk.Button(frm, text="Edit data", command=root.destroy).grid(column=1, row=1)
    # ttk.Button(frm, text="Save", command=root.destroy).grid(column=1, row=2)
    # ttk.Button(frm, text="Slice", command=root.destroy).grid(column=1, row=3)
    # ttk.Button(frm, text="Diagrams", command=root.destroy).grid(column=1, row=4)
    # ttk.Button(frm, text="About", command=root.destroy).grid(column=1, row=5)
    #
    #
    #
    #
    #
    # root.mainloop()
