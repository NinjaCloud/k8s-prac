Absolutely! Here are **10 practical tasks** for your freshers based on the labs you have created, with **clear problem statements** and **answers (solutions)** they can implement. These tasks reinforce the concepts and provide hands-on practice.

---

# 📝 Bash Scripting Tasks for Freshers

---

## Task 1: **Create a Script with Shebang and Comments**

**Problem:**
Write a Bash script that prints your name and student ID. Include a shebang line and comments explaining each part of the script.

**Answer:**

```bash
#!/bin/bash
# This script prints name and student ID

echo "Name: John Doe"
echo "Student ID: 123456"
```

---

## Task 2: **Variable Declaration and Printing**

**Problem:**
Declare two variables, `first_name` and `last_name`, assign your first and last name, then print them in a single line.

**Answer:**

```bash
#!/bin/bash

first_name="John"
last_name="Doe"

echo "Full Name: $first_name $last_name"
```

---

## Task 3: **Command Substitution**

**Problem:**
Write a script that stores the current date in a variable using command substitution, then prints “Today’s date is: <date>”.

**Answer:**

```bash
#!/bin/bash

current_date=$(date)
echo "Today's date is: $current_date"
```

---

## Task 4: **User Input and Output**

**Problem:**
Write a script that asks the user for their favorite programming language and then prints “You like <language>”.

**Answer:**

```bash
#!/bin/bash

echo "Enter your favorite programming language:"
read language
echo "You like $language"
```

---

## Task 5: **Simple Conditional Statement**

**Problem:**
Write a script that reads a number from the user and prints “Even number” if the number is even, otherwise “Odd number”.

**Answer:**

```bash
#!/bin/bash

echo "Enter a number:"
read num

if [ $((num % 2)) -eq 0 ]; then
    echo "Even number"
else
    echo "Odd number"
fi
```

---

## Task 6: **Comparison and Logical Operators**

**Problem:**
Write a script that asks for a user’s age and username. Grant access only if the username is “admin” AND the age is 18 or older.

**Answer:**

```bash
#!/bin/bash

echo "Enter username:"
read username

echo "Enter age:"
read age

if [[ "$username" == "admin" && $age -ge 18 ]]; then
    echo "Access granted."
else
    echo "Access denied."
fi
```

---

## Task 7: **Loop to Print Numbers**

**Problem:**
Write a script using a `for` loop to print all numbers from 1 to 10.

**Answer:**

```bash
#!/bin/bash

for i in {1..10}
do
    echo "Number: $i"
done
```

---

## Task 8: **Function to Greet User**

**Problem:**
Write a function called `greet` that takes a name as argument and prints “Hello, <name>!”. Call the function with a user input.

**Answer:**

```bash
#!/bin/bash

greet() {
    echo "Hello, $1!"
}

echo "Enter your name:"
read name

greet "$name"
```

---

## Task 9: **File Operations**

**Problem:**
Write a script to check if a file named `data.txt` exists. If not, create it and write “Sample data” inside. Finally, display the contents.

**Answer:**

```bash
#!/bin/bash

filename="data.txt"

if [ -f "$filename" ]; then
    echo "$filename exists."
else
    echo "$filename not found. Creating file..."
    echo "Sample data" > "$filename"
fi

echo "File contents:"
cat "$filename"
```

---

## Task 10: **Error Handling**

**Problem:**
Write a script to create a directory named `backup`. If creation fails (e.g., directory already exists or permission denied), print “Failed to create directory” and exit.

**Answer:**

```bash
#!/bin/bash

mkdir backup 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Failed to create directory."
    exit 1
else
    echo "Directory 'backup' created successfully."
fi
```

---

# 📌 How to Assign

* Assign tasks progressively (Task 1 → Task 10)
* Encourage them to try running and modifying the scripts
* Discuss error messages and help debug during class

---

If you want, I can also help you generate **answer keys with comments** or **bonus questions** based on these tasks!
