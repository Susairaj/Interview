Linux


# The Ultimate Linux Mastery Guide
## A Comprehensive, Beginner-Friendly Tutorial

---

# 📋 TABLE OF CONTENTS

1. **Navigating the Linux File System**
2. **File and Directory Management**
3. **Viewing and Manipulating File Content**
4. **File Permissions and Ownership**
5. **User and Group Management**
6. **Process Management**
7. **Package Management**
8. **Disk and Storage Management**
9. **Networking Essentials**
10. **Input/Output Redirection and Piping**
11. **Search, Find, and Filter**
12. **Compression and Archiving**
13. **Shell Scripting**
14. **Cron Jobs and Task Scheduling**
15. **System Monitoring and Logs**

---

---

# SECTION 1: NAVIGATING THE LINUX FILE SYSTEM

The Linux file system is a tree structure that starts at the root directory `/`. Understanding how to move around this tree is the most fundamental skill you'll need.

---

## 1.1 — `pwd` (Print Working Directory)

**What it does:** Shows you exactly where you are in the file system right now.

**Think of it like:** Looking at the street sign to figure out which street you're on.

```bash
pwd
```

**Example Output:**
```
/home/john
```

This tells you that you're currently inside the `john` folder, which is inside the `home` folder, which is inside the root `/` directory.

**Practical Application:** When you open multiple terminal windows or get lost after several `cd` commands, `pwd` instantly tells you your current location.

---

## 1.2 — `cd` (Change Directory)

**What it does:** Moves you from one directory to another.

**Think of it like:** Walking from one room to another in a building.

```bash
# Move into a specific directory
cd /var/log

# Move into a subdirectory of your current location
cd Documents

# Move UP one level (to the parent directory)
cd ..

# Move UP two levels
cd ../..

# Go directly to your home directory (three equivalent ways)
cd
cd ~
cd $HOME

# Go back to the PREVIOUS directory you were in
cd -
```

**Step-by-Step Example:**

```bash
pwd
# Output: /home/john

cd /var/log
pwd
# Output: /var/log

cd ..
pwd
# Output: /var

cd ~
pwd
# Output: /home/john

cd -
# Output: /var  (takes you back to where you just were)
```

**Key Concepts:**
- **Absolute path:** Starts from root `/` — Example: `/home/john/Documents`
- **Relative path:** Starts from your current location — Example: `Documents/Work`
- `.` means "current directory"
- `..` means "parent directory (one level up)"

**Practical Application:** Every single task in Linux requires you to be in the right directory or reference the right path. Mastering `cd` is like learning to walk before you run.

---

## 1.3 — `ls` (List Directory Contents)

**What it does:** Shows you what files and folders exist in a directory.

**Think of it like:** Opening a folder on your desktop and seeing what's inside.

```bash
# Basic listing
ls

# Long format with details (permissions, owner, size, date)
ls -l

# Show hidden files (files starting with a dot)
ls -a

# Combine: long format + hidden files
ls -la

# Human-readable file sizes (KB, MB, GB instead of bytes)
ls -lh

# Sort by modification time (newest first)
ls -lt

# Sort by file size (largest first)
ls -lS

# Reverse any sort order
ls -lr

# List contents of a SPECIFIC directory without going there
ls -l /etc

# Recursive listing (show contents of all subdirectories too)
ls -R

# Show directories themselves, not their contents
ls -ld /etc

# Combine multiple options for maximum detail
ls -lahS
```

**Step-by-Step Example of `ls -l` Output:**

```
-rw-r--r--  1  john  developers  4096  Oct 15 09:30  report.txt
```

Let me break down every single column:

| Column | Value | Meaning |
|--------|-------|---------|
| `-rw-r--r--` | File permissions | Who can read, write, execute |
| `1` | Hard link count | Number of hard links to this file |
| `john` | Owner | The user who owns this file |
| `developers` | Group | The group assigned to this file |
| `4096` | Size | File size in bytes |
| `Oct 15 09:30` | Timestamp | When the file was last modified |
| `report.txt` | Name | The file or directory name |

The very first character tells you the type:
- `-` = regular file
- `d` = directory
- `l` = symbolic link
- `b` = block device
- `c` = character device

**Practical Application:** Before modifying, copying, or deleting files, you almost always use `ls` first to survey the landscape and confirm you're working with the right files.

---

## 1.4 — Understanding the Linux Directory Structure

```
/                   ← Root: the very top of the file system
├── /bin            ← Essential user command binaries (ls, cp, mv)
├── /sbin           ← System binaries (for admin tasks like fdisk, iptables)
├── /etc            ← Configuration files for the entire system
├── /home           ← Home directories for regular users
│   ├── /home/john
│   └── /home/jane
├── /root           ← Home directory for the root (admin) user
├── /var            ← Variable data: logs, databases, mail, print queues
│   └── /var/log    ← System log files
├── /tmp            ← Temporary files (cleared on reboot)
├── /usr            ← User programs and data (read-only)
│   ├── /usr/bin    ← Most user commands
│   └── /usr/lib    ← Libraries for /usr/bin programs
├── /opt            ← Optional/third-party software
├── /dev            ← Device files (hard drives, USB, terminals)
├── /proc           ← Virtual filesystem for process/system info
├── /sys            ← Virtual filesystem for kernel/device info
├── /boot           ← Boot loader files, kernel
├── /lib            ← Essential shared libraries
├── /mnt            ← Temporary mount point for filesystems
└── /media          ← Mount point for removable media (USB, CD)
```

---

---

# SECTION 2: FILE AND DIRECTORY MANAGEMENT

This section teaches you how to create, copy, move, rename, and delete files and directories.

---

## 2.1 — `touch` (Create Files / Update Timestamps)

**What it does:** Creates a new empty file, or updates the timestamp of an existing file.

```bash
# Create a single empty file
touch myfile.txt

# Create multiple files at once
touch file1.txt file2.txt file3.txt

# Create files with a pattern using brace expansion
touch report_{january,february,march}.txt
# Creates: report_january.txt, report_february.txt, report_march.txt

# Create numbered files
touch file{1..10}.txt
# Creates: file1.txt through file10.txt

# Update the timestamp of an existing file (without modifying content)
touch existing_file.txt
```

**Practical Application:** Quickly scaffold out a project structure, create placeholder files, or update timestamps for build systems that rely on file modification times.

---

## 2.2 — `mkdir` (Make Directory)

**What it does:** Creates new directories (folders).

```bash
# Create a single directory
mkdir projects

# Create multiple directories
mkdir dir1 dir2 dir3

# Create nested directories (parent + child in one command)
# The -p flag creates parent directories as needed
mkdir -p projects/webapp/src/components

# Without -p, this would FAIL if 'projects' doesn't exist
# With -p, it creates the ENTIRE path

# Create directory with specific permissions
mkdir -m 755 shared_folder

# Verbose output (tells you what it created)
mkdir -v new_directory
# Output: mkdir: created directory 'new_directory'
```

**Step-by-Step Example:**

```bash
# You want to set up a project structure
mkdir -p myproject/{src,tests,docs,config}
mkdir -p myproject/src/{main,utils,models}

# Let's see what we built
ls -R myproject/
# Output:
# myproject/:
# config  docs  src  tests
#
# myproject/src:
# main  models  utils
```

**Practical Application:** Setting up project structures, organizing files, creating backup directories.

---

## 2.3 — `cp` (Copy Files and Directories)

**What it does:** Creates a duplicate of a file or directory.

```bash
# Copy a file to a new name (same directory)
cp original.txt copy.txt

# Copy a file to a different directory
cp report.txt /home/john/backups/

# Copy a file to a different directory WITH a new name
cp report.txt /home/john/backups/report_backup.txt

# Copy multiple files to a directory
cp file1.txt file2.txt file3.txt /home/john/backups/

# Copy an entire directory (MUST use -r for recursive)
cp -r my_project/ my_project_backup/

# Interactive mode: ask before overwriting
cp -i original.txt copy.txt
# Output: cp: overwrite 'copy.txt'? y

# Preserve file attributes (permissions, timestamps, ownership)
cp -p important.txt backup_important.txt

# Preserve EVERYTHING (permissions, timestamps, links, etc.)
cp -a source_dir/ destination_dir/

# Verbose output (shows what's being copied)
cp -v file1.txt /backups/
# Output: 'file1.txt' -> '/backups/file1.txt'

# Copy only if source is NEWER than destination
cp -u source.txt destination.txt

# Combine flags for a complete backup
cp -rav /home/john/project/ /backup/project_backup/
```

**Practical Application:** Creating backups, duplicating configuration files before editing them, deploying files to different locations.

---

## 2.4 — `mv` (Move / Rename Files and Directories)

**What it does:** Moves files to a new location OR renames them. Unlike `cp`, the original is removed.

```bash
# Rename a file
mv oldname.txt newname.txt

# Move a file to another directory
mv report.txt /home/john/Documents/

# Move a file to another directory AND rename it
mv report.txt /home/john/Documents/final_report.txt

# Move multiple files to a directory
mv file1.txt file2.txt file3.txt /home/john/archive/

# Rename a directory
mv old_project_name/ new_project_name/

# Interactive mode: ask before overwriting
mv -i source.txt destination.txt

# Don't overwrite if destination exists
mv -n source.txt destination.txt

# Verbose output
mv -v myfile.txt /tmp/
# Output: renamed 'myfile.txt' -> '/tmp/myfile.txt'

# Force move (no prompts, override -i if set in alias)
mv -f source.txt destination.txt
```

**Key Difference from `cp`:**
- `cp` = duplicate (original stays)
- `mv` = relocate (original is gone)

**Practical Application:** Organizing files into folders, renaming files to follow naming conventions, moving completed work to archive directories.

---

## 2.5 — `rm` (Remove Files and Directories)

**What it does:** Permanently deletes files and directories. **There is no trash can in Linux command line — deletion is permanent.**

```bash
# Remove a single file
rm unwanted_file.txt

# Remove multiple files
rm file1.txt file2.txt file3.txt

# Remove with confirmation prompt (RECOMMENDED for safety)
rm -i important_file.txt
# Output: rm: remove regular file 'important_file.txt'? y

# Remove a directory and ALL its contents (recursive)
rm -r old_project/

# Force removal (no prompts, no errors for missing files)
rm -f nonexistent_file.txt

# Force remove a directory and everything inside (USE WITH EXTREME CAUTION)
rm -rf old_project/

# Verbose output (shows each file as it's deleted)
rm -rv old_project/
# Output:
# removed 'old_project/file1.txt'
# removed 'old_project/file2.txt'
# removed directory 'old_project/'

# Remove all files matching a pattern
rm *.log
rm *.tmp
```

**⚠️ DANGER ZONE — Commands That Can Destroy Your System:**

```bash
# NEVER run these commands:
rm -rf /           # Deletes EVERYTHING on the system
rm -rf /*          # Same effect
rm -rf ~           # Deletes your entire home directory
rm -rf .           # Deletes everything in current directory
```

**Safety Tips:**
1. Always use `rm -i` until you're confident
2. Use `ls` first to preview what you're about to delete: `ls *.log` before `rm *.log`
3. Consider using `trash-cli` package instead of `rm` for recoverable deletion

---

## 2.6 — `rmdir` (Remove Empty Directories)

**What it does:** Removes directories, but ONLY if they are empty. This is safer than `rm -r`.

```bash
# Remove an empty directory
rmdir empty_folder

# Remove nested empty directories
rmdir -p parent/child/grandchild
# Removes grandchild, then child, then parent (only if all are empty)
```

---

## 2.7 — `ln` (Create Links)

**What it does:** Creates links (shortcuts) to files.

```bash
# Create a HARD link (another name for the same file data)
ln original.txt hardlink.txt

# Create a SYMBOLIC (soft) link (a pointer/shortcut to a file)
ln -s /home/john/scripts/deploy.sh /usr/local/bin/deploy

# Create a symbolic link to a directory
ln -s /var/log/nginx/ ~/nginx-logs

# View where a symbolic link points
ls -l /usr/local/bin/deploy
# Output: lrwxrwxrwx 1 root root 32 Oct 15 ... deploy -> /home/john/scripts/deploy.sh
```

**Hard Link vs Symbolic Link:**

| Feature | Hard Link | Symbolic Link |
|---------|-----------|---------------|
| Points to | The actual data on disk | The file path/name |
| Survives original deletion | ✅ Yes | ❌ No (becomes broken) |
| Works across filesystems | ❌ No | ✅ Yes |
| Can link directories | ❌ No | ✅ Yes |
| Has its own inode | ❌ Same inode | ✅ Different inode |

**Practical Application:** Creating shortcuts to deeply nested files, making a command available system-wide by linking a script to `/usr/local/bin/`, pointing to the latest version of a file (`ln -s app-v2.3/ current`).

---

---

# SECTION 3: VIEWING AND MANIPULATING FILE CONTENT

---

## 3.1 — `cat` (Concatenate and Display)

**What it does:** Displays the entire content of a file, or combines multiple files.

```bash
# Display file contents
cat myfile.txt

# Display with line numbers
cat -n myfile.txt

# Display with line numbers (skip blank line numbering)
cat -b myfile.txt

# Show hidden characters (tabs as ^I, end of line as $)
cat -A myfile.txt

# Combine multiple files and display
cat file1.txt file2.txt

# Combine multiple files into one new file
cat file1.txt file2.txt file3.txt > combined.txt

# Append a file to another file
cat extra_data.txt >> existing_file.txt

# Create a file and type content directly (press Ctrl+D to save and exit)
cat > newfile.txt
This is line one.
This is line two.
# Press Ctrl+D
```

**Practical Application:** Quickly viewing configuration files, combining log files, creating small files without opening an editor.

---

## 3.2 — `less` and `more` (Page Through Files)

**What it does:** Lets you scroll through large files one page at a time (instead of dumping everything on screen like `cat`).

```bash
# View a file with less (PREFERRED — more features than 'more')
less /var/log/syslog

# View a file with more (older, simpler)
more /var/log/syslog
```

**Navigation inside `less`:**

| Key | Action |
|-----|--------|
| `Space` or `f` | Forward one page |
| `b` | Back one page |
| `Enter` or `↓` | Forward one line |
| `k` or `↑` | Back one line |
| `g` | Go to the beginning of the file |
| `G` | Go to the end of the file |
| `/searchterm` | Search forward for "searchterm" |
| `?searchterm` | Search backward for "searchterm" |
| `n` | Next search result |
| `N` | Previous search result |
| `q` | Quit |
| `F` | Follow mode (like `tail -f`, live updates) |

**Practical Application:** Reading log files, configuration files, or any file that's too large for `cat` to display meaningfully.

---

## 3.3 — `head` and `tail` (View Beginning / End of Files)

**What it does:** `head` shows the first lines of a file; `tail` shows the last lines.

```bash
# Show the first 10 lines (default)
head /var/log/syslog

# Show the first 20 lines
head -n 20 /var/log/syslog
# Or shorthand:
head -20 /var/log/syslog

# Show the first 100 bytes
head -c 100 /var/log/syslog

# Show the last 10 lines (default)
tail /var/log/syslog

# Show the last 50 lines
tail -n 50 /var/log/syslog

# FOLLOW a file in real-time (watch for new lines as they're added)
tail -f /var/log/syslog

# Follow and retry if the file is recreated (useful for rotating logs)
tail -F /var/log/syslog

# Show the last 100 lines and then follow
tail -n 100 -f /var/log/syslog
```

**Practical Application:** `tail -f` is one of the most-used commands in production environments — it lets you watch log files in real time while debugging issues. `head` is great for previewing CSV files or data files to understand their structure.

---

## 3.4 — `wc` (Word Count)

**What it does:** Counts lines, words, and characters in a file.

```bash
# Show lines, words, and characters
wc myfile.txt
# Output: 42  318  1847  myfile.txt
# (42 lines, 318 words, 1847 characters)

# Count only lines
wc -l myfile.txt
# Output: 42 myfile.txt

# Count only words
wc -w myfile.txt

# Count only characters (bytes)
wc -c myfile.txt

# Count characters (multibyte-aware)
wc -m myfile.txt

# Count lines in multiple files
wc -l *.txt

# Common use with pipes: count how many files in a directory
ls | wc -l

# Count how many running processes
ps aux | wc -l
```

---

## 3.5 — `sort` (Sort Lines)

```bash
# Sort alphabetically
sort names.txt

# Sort in reverse order
sort -r names.txt

# Sort numerically
sort -n numbers.txt

# Sort by a specific column (e.g., column 2, fields separated by commas)
sort -t',' -k2 data.csv

# Sort and remove duplicates
sort -u names.txt

# Sort by human-readable numbers (1K, 2M, 3G)
sort -h filesizes.txt

# Case-insensitive sort
sort -f names.txt
```

---

## 3.6 — `uniq` (Report or Remove Duplicates)

**Important:** `uniq` only removes ADJACENT duplicates. Always `sort` first.

```bash
# Remove adjacent duplicate lines
sort names.txt | uniq

# Count occurrences of each line
sort names.txt | uniq -c

# Show ONLY duplicate lines
sort names.txt | uniq -d

# Show ONLY unique (non-duplicate) lines
sort names.txt | uniq -u

# Case-insensitive comparison
sort names.txt | uniq -i
```

**Step-by-Step Example:**

```bash
# File: colors.txt contains:
# red
# blue
# red
# green
# blue
# blue

sort colors.txt | uniq -c | sort -rn
# Output:
#   3 blue
#   2 red
#   1 green
# This shows the most common entries first!
```

---

## 3.7 — `cut` (Extract Columns/Fields)

```bash
# Extract characters 1-5 from each line
cut -c1-5 myfile.txt

# Extract the first field from a colon-separated file
cut -d':' -f1 /etc/passwd

# Extract fields 1 and 3
cut -d':' -f1,3 /etc/passwd

# Extract fields 1 through 4
cut -d':' -f1-4 /etc/passwd

# Use comma as delimiter and get second column
cut -d',' -f2 data.csv

# Extract from field 3 to end of line
cut -d':' -f3- /etc/passwd
```

**Step-by-Step Example:**

```bash
# /etc/passwd contains lines like:
# john:x:1000:1000:John Smith:/home/john:/bin/bash

# Get just usernames:
cut -d':' -f1 /etc/passwd
# Output: john, root, daemon, etc.

# Get usernames and their home directories:
cut -d':' -f1,6 /etc/passwd
# Output: john:/home/john
```

---

## 3.8 — `tr` (Translate/Transform Characters)

```bash
# Convert lowercase to uppercase
echo "hello world" | tr 'a-z' 'A-Z'
# Output: HELLO WORLD

# Convert uppercase to lowercase
echo "HELLO" | tr 'A-Z' 'a-z'
# Output: hello

# Replace spaces with underscores
echo "my file name" | tr ' ' '_'
# Output: my_file_name

# Delete specific characters
echo "hello 123 world 456" | tr -d '0-9'
# Output: hello  world

# Squeeze repeated characters (replace multiple spaces with one)
echo "hello    world" | tr -s ' '
# Output: hello world

# Remove carriage returns (fix Windows line endings)
tr -d '\r' < windows_file.txt > unix_file.txt
```

---

## 3.9 — `diff` (Compare Files)

```bash
# Compare two files line by line
diff file1.txt file2.txt

# Side-by-side comparison
diff -y file1.txt file2.txt

# Unified format (like Git diffs — most readable)
diff -u file1.txt file2.txt

# Compare two directories
diff -r dir1/ dir2/

# Brief: just report IF files differ, not HOW
diff -q file1.txt file2.txt
# Output: Files file1.txt and file2.txt differ
```

---

## 3.10 — `nano`, `vi`/`vim` (Text Editors)

### nano (Beginner-Friendly)

```bash
# Open/create a file in nano
nano myfile.txt
```

**Nano Keyboard Shortcuts:**

| Shortcut | Action |
|----------|--------|
| `Ctrl+O` | Save (Write Out) |
| `Ctrl+X` | Exit |
| `Ctrl+K` | Cut a line |
| `Ctrl+U` | Paste a line |
| `Ctrl+W` | Search |
| `Ctrl+G` | Help |
| `Alt+U` | Undo |

### vim (Powerful but Steeper Learning Curve)

```bash
# Open/create a file in vim
vim myfile.txt
```

**Vim has THREE main modes:**

1. **Normal Mode** (default when you open vim) — for navigation and commands
2. **Insert Mode** (press `i`) — for typing text
3. **Command Mode** (press `:`) — for saving, quitting, etc.

**Essential Vim Commands:**

| Command | Action |
|---------|--------|
| `i` | Enter Insert mode (start typing) |
| `Esc` | Return to Normal mode |
| `:w` | Save |
| `:q` | Quit |
| `:wq` or `:x` | Save and quit |
| `:q!` | Quit WITHOUT saving |
| `dd` | Delete (cut) current line |
| `yy` | Copy (yank) current line |
| `p` | Paste below cursor |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `/searchterm` | Search |
| `:%s/old/new/g` | Find and replace ALL occurrences |
| `gg` | Go to beginning of file |
| `G` | Go to end of file |
| `:set number` | Show line numbers |

**Practical Application:** Every Linux system has `vi` installed. Even if you prefer `nano`, knowing basic `vim` is essential because you'll encounter systems where it's the only editor available.

---

---

# SECTION 4: FILE PERMISSIONS AND OWNERSHIP

This is one of the most critical concepts in Linux. Every file and directory has permissions that control who can read, write, or execute it.

---

## 4.1 — Understanding Permission Structure

When you run `ls -l`, you see something like this:

```
-rwxr-xr--  1  john  developers  4096  Oct 15 09:30  script.sh
```

The permission string `-rwxr-xr--` is divided into four parts:

```
-    rwx    r-x    r--
│     │      │      │
│     │      │      └── Others (everyone else)
│     │      └── Group (members of the file's group)
│     └── Owner/User (the file's owner)
└── File type (- = file, d = directory, l = link)
```

**The three permission types:**

| Symbol | Permission | For Files | For Directories |
|--------|-----------|-----------|-----------------|
| `r` | Read | View file contents | List directory contents (`ls`) |
| `w` | Write | Modify file | Create/delete files inside |
| `x` | Execute | Run as a program | Enter the directory (`cd`) |
| `-` | None | No permission | No permission |

**Numeric (Octal) Values:**

| Permission | Value |
|-----------|-------|
| `r` (read) | 4 |
| `w` (write) | 2 |
| `x` (execute) | 1 |
| `-` (none) | 0 |

You ADD the values together for each group:

```
rwx = 4+2+1 = 7  (full permissions)
r-x = 4+0+1 = 5  (read and execute)
r-- = 4+0+0 = 4  (read only)
rw- = 4+2+0 = 6  (read and write)
--- = 0+0+0 = 0  (no permissions)
```

**Common Permission Patterns:**

| Numeric | Symbolic | Meaning |
|---------|----------|---------|
| `755` | `rwxr-xr-x` | Owner: full; Group & Others: read+execute |
| `644` | `rw-r--r--` | Owner: read+write; Group & Others: read only |
| `700` | `rwx------` | Owner: full; nobody else gets anything |
| `666` | `rw-rw-rw-` | Everyone can read and write |
| `777` | `rwxrwxrwx` | Everyone can do everything (AVOID for security) |
| `600` | `rw-------` | Owner: read+write; nobody else |
| `444` | `r--r--r--` | Everyone can only read |

---

## 4.2 — `chmod` (Change Mode/Permissions)

**What it does:** Changes the permissions on a file or directory.

### Method 1: Numeric (Octal) Mode

```bash
# Give owner full permissions, group read+execute, others read only
chmod 754 myfile.txt
# Result: rwxr-xr--

# Make a script executable by everyone
chmod 755 script.sh
# Result: rwxr-xr-x

# Private file — only owner can read and write
chmod 600 secret.txt
# Result: rw-------

# Full permissions for everyone (usually a bad idea)
chmod 777 shared_file.txt
# Result: rwxrwxrwx

# Read-only for everyone
chmod 444 readonly.txt
# Result: r--r--r--
```

### Method 2: Symbolic Mode

```bash
# u = user/owner, g = group, o = others, a = all

# Add execute permission for the owner
chmod u+x script.sh

# Remove write permission from group and others
chmod go-w myfile.txt

# Add read permission for everyone
chmod a+r myfile.txt

# Set exact permissions for user (replaces existing)
chmod u=rwx script.sh

# Add execute for owner and group
chmod ug+x script.sh

# Remove all permissions for others
chmod o= secret.txt

# Make file readable and writable by owner only
chmod u=rw,go= private.txt

# Add write permission for group
chmod g+w shared_document.txt
```

### Recursive Permission Changes

```bash
# Change permissions for a directory AND everything inside it
chmod -R 755 my_project/

# Common pattern: directories get 755, files get 644
find my_project/ -type d -exec chmod 755 {} \;
find my_project/ -type f -exec chmod 644 {} \;
```

**Practical Application:**
- `chmod 755 deploy.sh` — Make a deployment script executable
- `chmod 600 ~/.ssh/id_rsa` — Secure your SSH private key (SSH requires this!)
- `chmod 644 index.html` — Web server files typically need to be readable

---

## 4.3 — `chown` (Change Ownership)

**What it does:** Changes the owner and/or group of a file or directory. Usually requires `sudo`.

```bash
# Change the owner of a file
sudo chown alice report.txt

# Change the owner AND group
sudo chown alice:developers report.txt

# Change only the group (note the colon before group name)
sudo chown :developers report.txt

# Recursive: change ownership of directory and ALL contents
sudo chown -R alice:developers /var/www/project/

# Verbose output
sudo chown -v alice:developers report.txt
# Output: changed ownership of 'report.txt' from john:john to alice:developers
```

---

## 4.4 — `chgrp` (Change Group)

**What it does:** Changes only the group ownership.

```bash
# Change the group of a file
sudo chgrp developers shared_file.txt

# Recursive
sudo chgrp -R www-data /var/www/html/
```

---

## 4.5 — `umask` (Default Permission Mask)

**What it does:** Sets the default permissions for newly created files and directories.

```bash
# View current umask
umask
# Output: 0022

# The umask is SUBTRACTED from the maximum permissions:
# Files:       666 - 022 = 644 (rw-r--r--)
# Directories: 777 - 022 = 755 (rwxr-xr-x)

# Set a more restrictive umask
umask 077
# Files:       666 - 077 = 600 (rw-------)
# Directories: 777 - 077 = 700 (rwx------)

# View umask in symbolic format
umask -S
# Output: u=rwx,g=rx,o=rx
```

**Practical Application:** On multi-user systems, setting `umask 077` ensures new files you create are private by default.

---

## 4.6 — Special Permissions: SUID, SGID, Sticky Bit

### SUID (Set User ID) — Numeric value: 4

When set on an executable, it runs with the **owner's permissions**, regardless of who executes it.

```bash
# Set SUID
chmod u+s program
chmod 4755 program

# Example: /usr/bin/passwd has SUID so regular users can change their own passwords
ls -l /usr/bin/passwd
# -rwsr-xr-x 1 root root ... /usr/bin/passwd
#    ^--- 's' instead of 'x' means SUID is set
```

### SGID (Set Group ID) — Numeric value: 2

On files: runs with the group's permissions. On directories: new files inherit the directory's group.

```bash
# Set SGID on a directory (very useful for shared folders)
chmod g+s shared_project/
chmod 2775 shared_project/

# Now any file created inside shared_project/ will inherit its group
```

### Sticky Bit — Numeric value: 1

On directories: only the file owner can delete their own files (even if others have write access).

```bash
# Set sticky bit
chmod +t /tmp
chmod 1777 /tmp

# Check it
ls -ld /tmp
# drwxrwxrwt ... /tmp
#           ^--- 't' means sticky bit is set
```

**Practical Application:** `/tmp` has the sticky bit set so that users can create temp files but can't delete each other's files.

---

---

# SECTION 5: USER AND GROUP MANAGEMENT

---

## 5.1 — User Management Commands

```bash
# See who you are currently logged in as
whoami
# Output: john

# See detailed info about a user
id john
# Output: uid=1000(john) gid=1000(john) groups=1000(john),27(sudo),44(video)

# See all currently logged-in users
who
w        # More detailed version

# List recent logins
last

# List failed login attempts
sudo lastb

# View user account details
sudo cat /etc/passwd     # User account information
sudo cat /etc/shadow     # Encrypted passwords (restricted)
sudo cat /etc/group      # Group information
```

### Creating Users

```bash
# Create a new user (basic)
sudo useradd newuser

# Create a user with a home directory, default shell, and comment
sudo useradd -m -s /bin/bash -c "Jane Smith" jane
# -m = create home directory
# -s = set login shell
# -c = comment/full name

# Create a user and add them to additional groups
sudo useradd -m -s /bin/bash -G sudo,developers jane

# Set/change a user's password
sudo passwd jane
# Prompts: New password: ********

# The easier all-in-one command (Debian/Ubuntu)
sudo adduser jane
# Interactive: asks for password, full name, etc. automatically
```

### Modifying Users

```bash
# Change a user's default shell
sudo usermod -s /bin/zsh john

# Add a user to an additional group (IMPORTANT: use -aG, not just -G)
sudo usermod -aG docker john
# -a = APPEND to existing groups
# -G = specify group(s)
# Without -a, the user would be REMOVED from all other groups!

# Add user to multiple groups
sudo usermod -aG sudo,developers,docker john

# Change the user's home directory
sudo usermod -d /new/home/john -m john
# -m = move contents of old home to new location

# Lock a user account (disable login)
sudo usermod -L john

# Unlock a user account
sudo usermod -U john

# Change username
sudo usermod -l newjohn oldjohn

# Set account expiration date
sudo usermod -e 2025-12-31 contractor
```

### Deleting Users

```bash
# Delete a user (keep their home directory)
sudo userdel john

# Delete a user AND their home directory
sudo userdel -r john

# Easier interactive version (Debian/Ubuntu)
sudo deluser john
sudo deluser --remove-home john
```

---

## 5.2 — Group Management

```bash
# Create a new group
sudo groupadd developers

# Create a group with a specific GID
sudo groupadd -g 1500 devops

# Delete a group
sudo groupdel developers

# Add a user to a group
sudo usermod -aG developers john

# Alternative way to add user to a group (Debian/Ubuntu)
sudo adduser john developers

# Remove a user from a group (Debian/Ubuntu)
sudo deluser john developers

# See what groups a user belongs to
groups john
# Output: john : john sudo developers docker

# See all groups on the system
cat /etc/group

# Change the primary group of a user
sudo usermod -g developers john
```

---

## 5.3 — `sudo` and `su` (Privilege Escalation)

```bash
# Run a single command as root
sudo apt update

# Open a root shell
sudo -i
# Or:
sudo su -

# Run a command as a different user
sudo -u www-data whoami
# Output: www-data

# Switch to another user account
su - jane
# Prompts for jane's password

# Edit the sudoers file (ALWAYS use visudo for safety)
sudo visudo

# Check what sudo privileges you have
sudo -l
```

**Example sudoers entry:**
```
# User john can run all commands on all hosts
john ALL=(ALL:ALL) ALL

# User jane can only restart nginx without a password
jane ALL=(ALL) NOPASSWD: /usr/sbin/service nginx restart
```

---

---

# SECTION 6: PROCESS MANAGEMENT

A process is any running instance of a program. Understanding how to view, control, and manage processes is essential for Linux system administration.

---

## 6.1 — `ps` (Process Status)

**What it does:** Shows a snapshot of current running processes.

```bash
# Show processes running in your current terminal session
ps

# Show ALL processes on the system (BSD syntax — most common)
ps aux

# Show ALL processes (Unix/System V syntax)
ps -ef

# Show processes in a tree format (shows parent-child relationships)
ps auxf

# Show only processes for a specific user
ps -u john

# Show only a specific process by name
ps aux | grep nginx

# Show only specific columns
ps -eo pid,ppid,user,%cpu,%mem,command

# Sort by CPU usage (descending)
ps aux --sort=-%cpu

# Sort by memory usage (descending)
ps aux --sort=-%mem

# Show top 10 CPU-consuming processes
ps aux --sort=-%cpu | head -11

# Show process tree
ps -ejH
```

**Understanding `ps aux` Output:**

```
USER   PID  %CPU %MEM  VSZ   RSS  TTY  STAT START TIME COMMAND
root     1   0.0  0.3 16844  6892 ?    Ss   Oct14 0:05 /sbin/init
john  1234   2.5  1.2 45820 24680 pts/0 S+ 09:30 0:42 python3 app.py
```

| Column | Meaning |
|--------|---------|
| `USER` | Who owns the process |
| `PID` | Process ID (unique identifier) |
| `%CPU` | CPU usage percentage |
| `%MEM` | Memory usage percentage |
| `VSZ` | Virtual memory size (KB) |
| `RSS` | Resident Set Size — actual physical memory used (KB) |
| `TTY` | Terminal associated (? = no terminal) |
| `STAT` | Process state (see below) |
| `START` | When the process started |
| `TIME` | Total CPU time consumed |
| `COMMAND` | The command that started the process |

**Process States (STAT column):**

| State | Meaning |
|-------|---------|
| `R` | Running |
| `S` | Sleeping (waiting for an event) |
| `D` | Uninterruptible sleep (usually I/O) |
| `T` | Stopped (suspended) |
| `Z` | Zombie (completed but not cleaned up by parent) |
| `+` | Running in the foreground |
| `s` | Session leader |
| `l` | Multi-threaded |
| `<` | High priority |
| `N` | Low priority |

---

## 6.2 — `top` and `htop` (Real-Time Process Monitoring)

### `top` (Included with every Linux installation)

```bash
# Launch top
top

# Launch showing only a specific user's processes
top -u john

# Launch sorted by memory usage
top -o %MEM
```

**Inside `top` — Interactive Commands:**

| Key | Action |
|-----|--------|
| `q` | Quit |
| `k` | Kill a process (prompts for PID) |
| `r` | Renice (change priority of a process) |
| `M` | Sort by memory usage |
| `P` | Sort by CPU usage |
| `T` | Sort by running time |
| `1` | Show individual CPU cores |
| `c` | Toggle full command path |
| `h` | Help |
| `Space` | Refresh immediately |

**Understanding the `top` Header:**

```
top - 14:30:25 up 5 days, 3:22, 2 users, load average: 0.52, 0.38, 0.41
Tasks: 214 total, 1 running, 213 sleeping, 0 stopped, 0 zombie
%Cpu(s): 3.2 us, 1.5 sy, 0.0 ni, 94.8 id, 0.3 wa, 0.0 hi, 0.2 si
MiB Mem:  7856.4 total, 1245.2 free, 3891.0 used, 2720.2 buff/cache
MiB Swap: 2048.0 total, 2048.0 free,    0.0 used. 3641.6 avail Mem
```

| Field | Meaning |
|-------|---------|
| `up 5 days` | System has been running for 5 days |
| `load average: 0.52, 0.38, 0.41` | CPU load over 1, 5, 15 minutes |
| `us` | User space CPU usage |
| `sy` | System/kernel CPU usage |
| `id` | Idle CPU |
| `wa` | CPU time waiting for I/O |

**Rule of thumb for load average:** If the number equals your CPU core count, the system is fully loaded. Above that = overloaded.

### `htop` (Enhanced, Colorful Version — Install Separately)

```bash
# Install htop
sudo apt install htop       # Debian/Ubuntu
sudo yum install htop       # CentOS/RHEL
sudo dnf install htop       # Fedora

# Launch htop
htop
```

`htop` provides a more intuitive, colorful, and interactive interface. You can scroll through processes, use the mouse, and see visual CPU/memory bars.

---

## 6.3 — `kill`, `killall`, `pkill` (Terminate Processes)

### Kill Signals

| Signal | Number | Meaning |
|--------|--------|---------|
| `SIGHUP` | 1 | Hangup — often used to reload configuration |
| `SIGINT` | 2 | Interrupt (same as Ctrl+C) |
| `SIGKILL` | 9 | Force kill — CANNOT be caught or ignored |
| `SIGTERM` | 15 | Graceful termination (default) |
| `SIGSTOP` | 19 | Pause/stop the process |
| `SIGCONT` | 18 | Resume a stopped process |

### `kill` (Send signal by PID)

```bash
# Gracefully terminate a process (sends SIGTERM — default)
kill 1234

# Force kill a process (sends SIGKILL — last resort)
kill -9 1234
# Or:
kill -SIGKILL 1234

# Send hangup signal (often reloads configuration)
kill -1 1234
kill -HUP 1234

# List all available signals
kill -l
```

### `killall` (Kill by process name)

```bash
# Kill all processes named "firefox"
killall firefox

# Force kill all instances
killall -9 firefox

# Kill processes by a specific user
killall -u john

# Interactive: ask before each kill
killall -i firefox
```

### `pkill` (Kill by pattern matching)

```bash
# Kill processes matching a pattern
pkill firefox

# Kill by exact name
pkill -x firefox

# Kill all processes owned by a user
pkill -u john

# Kill processes matching a pattern (case insensitive)
pkill -i python
```

---

## 6.4 — Job Control (Background & Foreground Processes)

```bash
# Run a command in the background (add & at the end)
python3 server.py &

# See all background jobs in current terminal
jobs
# Output:
# [1]+ Running    python3 server.py &
# [2]- Stopped    vim report.txt

# Bring a background job to the foreground
fg %1        # Bring job 1 to foreground
fg           # Bring the most recent job to foreground

# Suspend/pause a running foreground process
# Press Ctrl+Z

# Resume a suspended process in the BACKGROUND
bg %1
bg           # Resume most recent suspended job

# Disown a job (keep it running even if you close the terminal)
disown %1

# Run a command that survives terminal closing
nohup python3 long_script.py &
# Output is saved to nohup.out

# Or redirect output explicitly
nohup python3 long_script.py > output.log 2>&1 &
```

**Step-by-Step Example:**

```bash
# 1. Start a long process
sleep 300

# 2. Oh wait, I need my terminal! Press Ctrl+Z to suspend it
# Output: [1]+ Stopped    sleep 300

# 3. Resume it in the background
bg %1
# Output: [1]+ sleep 300 &

# 4. Verify it's running
jobs
# Output: [1]+ Running    sleep 300 &

# 5. You can now use your terminal for other things!

# 6. When ready, bring it back to foreground
fg %1
```

---

## 6.5 — `nice` and `renice` (Process Priority)

**What it does:** Controls CPU scheduling priority. Nice values range from -20 (highest priority) to 19 (lowest priority). Default is 0.

```bash
# Start a process with a lower priority (nicer to other processes)
nice -n 10 python3 heavy_computation.py

# Start with the lowest priority
nice -n 19 ./backup_script.sh

# Start with higher priority (requires sudo)
sudo nice -n -10 ./critical_service

# Change priority of a running process
renice 15 -p 1234          # Set process 1234 to priority 15
sudo renice -5 -p 1234     # Set to higher priority (needs sudo)

# Change priority for all processes of a user
sudo renice 10 -u john
```

---

## 6.6 — `pgrep` (Find Process IDs)

```bash
# Find PID of a process by name
pgrep nginx
# Output:
# 1234
# 1235

# Show process name alongside PID
pgrep -a nginx
# Output:
# 1234 nginx: master process
# 1235 nginx: worker process

# Find PIDs for a specific user
pgrep -u john

# Count matching processes
pgrep -c nginx
# Output: 2
```

---

## 6.7 — `uptime` and `free` (System Overview)

```bash
# Show how long the system has been running + load averages
uptime
# Output: 14:30:25 up 5 days, 3:22, 2 users, load average: 0.52, 0.38, 0.41

# Show memory usage
free
free -h     # Human-readable (MB/GB)
# Output:
#               total    used    free   shared  buff/cache  available
# Mem:          7.7Gi   3.8Gi   1.2Gi   312Mi      2.7Gi      3.6Gi
# Swap:         2.0Gi      0B   2.0Gi

# What matters most: the "available" column — that's what's actually available for use
# Linux uses spare RAM for disk cache (buff/cache), but releases it when programs need it
```

---

---

# SECTION 7: PACKAGE MANAGEMENT

Package managers install, update, and remove software. Different Linux distributions use different package managers.

---

## 7.1 — APT (Debian, Ubuntu, Linux Mint)

```bash
# Update package lists (check for updates — does NOT install anything)
sudo apt update

# Upgrade all installed packages to their latest versions
sudo apt upgrade

# Update + upgrade in one step (with smart conflict resolution)
sudo apt full-upgrade

# Search for a package
apt search nginx

# Show detailed info about a package
apt show nginx

# Install a package
sudo apt install nginx

# Install multiple packages
sudo apt install nginx mysql-server php

# Install without prompts (auto-yes)
sudo apt install -y nginx

# Remove a package (keeps config files)
sudo apt remove nginx

# Remove a package AND its configuration files
sudo apt purge nginx

# Remove unnecessary dependencies
sudo apt autoremove

# List installed packages
apt list --installed

# List upgradable packages
apt list --upgradable

# Check if a specific package is installed
dpkg -l | grep nginx

# Install a .deb file
sudo dpkg -i package.deb
# Fix dependencies if dpkg fails:
sudo apt install -f
```

---

## 7.2 — YUM / DNF (CentOS, RHEL, Fedora)

```bash
# DNF is the modern replacement for YUM. Commands are nearly identical.

# Update all packages
sudo dnf update           # Fedora
sudo yum update           # CentOS/RHEL 7

# Search for a package
dnf search nginx

# Install a package
sudo dnf install nginx

# Remove a package
sudo dnf remove nginx

# List installed packages
dnf list installed

# Show package info
dnf info nginx

# Clean cached data
sudo dnf clean all

# List available groups (bundles of packages)
dnf group list

# Install a group
sudo dnf group install "Development Tools"

# Install a .rpm file
sudo dnf install package.rpm
```

---

## 7.3 — Snap and Flatpak (Universal Package Managers)

```bash
# Snap (Ubuntu and others)
sudo snap install vlc
snap list
sudo snap remove vlc
sudo snap refresh           # Update all snaps

# Flatpak (Fedora and others)
flatpak install flathub org.mozilla.firefox
flatpak list
flatpak uninstall org.mozilla.firefox
flatpak update
```

---

---

# SECTION 8: DISK AND STORAGE MANAGEMENT

---

## 8.1 — `df` (Disk Free Space)

**What it does:** Shows how much disk space is used and available on mounted filesystems.

```bash
# Show disk usage for all mounted filesystems
df

# Human-readable format (MB, GB)
df -h

# Show info for a specific filesystem/mount point
df -h /home

# Show filesystem type
df -hT

# Show only local filesystems (exclude network)
df -hl
```

**Example Output of `df -h`:**

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   23G   25G  48% /
/dev/sda2       200G  156G   34G  82% /home
tmpfs           3.9G  1.2M  3.9G   1% /tmp
```

**Practical Application:** Regularly check disk space to prevent systems from running out. A 100% full root partition will crash services.

---

## 8.2 — `du` (Disk Usage by File/Directory)

**What it does:** Shows how much space files and directories are consuming.

```bash
# Show size of each file and subdirectory in current directory
du -h

# Show only the total size of a specific directory
du -sh /home/john/Documents
# Output: 2.4G    /home/john/Documents

# Show sizes of all subdirectories (1 level deep)
du -h --max-depth=1 /home/john

# Show sizes and sort by size (find the biggest directories)
du -h --max-depth=1 /home/john | sort -hr

# Find the top 10 largest directories
du -h --max-depth=1 / 2>/dev/null | sort -hr | head -10

# Show apparent file size (not disk block usage)
du -sh --apparent-size myfile.iso

# Exclude certain patterns
du -h --exclude='*.log' /var/
```

---

## 8.3 — `lsblk` (List Block Devices)

```bash
# Show all block devices (disks, partitions)
lsblk

# Show with filesystem info
lsblk -f

# Example output:
# NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# sda      8:0    0   500G  0 disk
# ├─sda1   8:1    0   512M  0 part /boot
# ├─sda2   8:2    0    50G  0 part /
# └─sda3   8:3    0   449G  0 part /home
# sdb      8:16   0     1T  0 disk
# └─sdb1   8:17   0     1T  0 part /data
```

---

## 8.4 — `mount` and `umount` (Mount/Unmount Filesystems)

```bash
# Show all currently mounted filesystems
mount

# Mount a USB drive
sudo mount /dev/sdb1 /mnt/usb

# Mount with specific filesystem type
sudo mount -t ntfs /dev/sdb1 /mnt/usb

# Mount read-only
sudo mount -o ro /dev/sdb1 /mnt/usb

# Unmount
sudo umount /mnt/usb

# Force unmount (if busy)
sudo umount -f /mnt/usb

# Lazy unmount (detach now, clean up when no longer busy)
sudo umount -l /mnt/usb

# Remount a filesystem (e.g., change from read-only to read-write)
sudo mount -o remount,rw /

# Mount all filesystems defined in /etc/fstab
sudo mount -a
```

---

## 8.5 — `fdisk` (Partition Management)

```bash
# List all partitions
sudo fdisk -l

# Open interactive partition editor for a specific disk
sudo fdisk /dev/sdb
# Commands inside fdisk:
# p = print partition table
# n = new partition
# d = delete partition
# t = change partition type
# w = write changes and exit
# q = quit without saving
```

---

---

# SECTION 9: NETWORKING ESSENTIALS

---

## 9.1 — Checking Network Configuration

### `ip` (Modern replacement for `ifconfig`)

```bash
# Show all network interfaces and their IP addresses
ip addr show
# Or shortened:
ip a

# Show only IPv4 addresses
ip -4 addr show

# Show a specific interface
ip addr show eth0

# Show routing table (how traffic reaches different networks)
ip route show
# Or shortened:
ip r

# Show the default gateway
ip route | grep default
# Output: default via 192.168.1.1 dev eth0

# Show link status (up/down, speed)
ip link show

# Bring an interface up
sudo ip link set eth0 up

# Bring an interface down
sudo ip link set eth0 down

# Add an IP address to an interface
sudo ip addr add 192.168.1.100/24 dev eth0

# Remove an IP address
sudo ip addr del 192.168.1.100/24 dev eth0

# Show ARP table (IP-to-MAC address mappings)
ip neigh show
```

### `ifconfig` (Legacy — Still Widely Used)

```bash
# Show all interfaces
ifconfig

# Show a specific interface
ifconfig eth0

# Bring interface up/down
sudo ifconfig eth0 up
sudo ifconfig eth0 down
```

---

## 9.2 — `ping` (Test Connectivity)

**What it does:** Sends ICMP echo requests to test if a host is reachable and measures round-trip time.

```bash
# Ping a host (runs until you press Ctrl+C)
ping google.com

# Ping with a specific count (send 5 packets, then stop)
ping -c 5 google.com

# Ping with a specific interval (every 2 seconds instead of every 1)
ping -i 2 google.com

# Ping with a specific packet size
ping -s 1024 google.com

# Quiet mode — only show summary
ping -c 5 -q google.com

# Set a timeout (wait max 3 seconds for each reply)
ping -W 3 google.com
```

**Example Output:**

```
PING google.com (142.250.80.46): 56 data bytes
64 bytes from 142.250.80.46: icmp_seq=0 ttl=117 time=12.4 ms
64 bytes from 142.250.80.46: icmp_seq=1 ttl=117 time=11.8 ms
64 bytes from 142.250.80.46: icmp_seq=2 ttl=117 time=13.1 ms

--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 11.8/12.4/13.1/0.5 ms
```

**Practical Application:**
- `ping 8.8.8.8` — Test basic internet connectivity (Google's DNS)
- `ping 192.168.1.1` — Test connection to your router/gateway
- `ping localhost` — Test that networking stack itself is working

---

## 9.3 — `traceroute` / `tracepath` (Trace Network Path)

**What it does:** Shows the path packets take from your computer to a destination, revealing every router along the way.

```bash
# Trace the route to a host
traceroute google.com

# Using tracepath (doesn't require root)
tracepath google.com

# Use ICMP instead of UDP
sudo traceroute -I google.com

# Use TCP (useful when ICMP is blocked)
sudo traceroute -T google.com

# Set max hops
traceroute -m 20 google.com
```

**Example Output:**

```
traceroute to google.com (142.250.80.46), 30 hops max
 1  192.168.1.1 (192.168.1.1)       1.234 ms
 2  10.0.0.1 (10.0.0.1)             8.567 ms
 3  isp-router.example.com           12.345 ms
 ...
 9  lax-google-peer.net              11.890 ms
10  142.250.80.46 (142.250.80.46)    12.456 ms
```

**Practical Application:** When a website is slow, `traceroute` helps identify WHERE in the network path the delay is occurring.

---

## 9.4 — `netstat` and `ss` (Network Statistics)

### `ss` (Modern — Faster)

```bash
# Show all listening TCP ports
ss -tlnp
# -t = TCP
# -l = listening (waiting for connections)
# -n = show port numbers (not service names)
# -p = show process using the port

# Show all listening UDP ports
ss -ulnp

# Show ALL connections (listening + established)
ss -tunap

# Show only established connections
ss -t state established

# Show connections on a specific port
ss -tlnp | grep :80

# Show connections for a specific process
ss -tlnp | grep nginx

# Summary statistics
ss -s
```

### `netstat` (Legacy — Still Common)

```bash
# Show all listening ports with process info
sudo netstat -tlnp

# Show all connections
netstat -an

# Show routing table
netstat -r

# Show network interface statistics
netstat -i

# Show connections with process info
sudo netstat -tunap
```

**Example Output of `ss -tlnp`:**

```
State   Recv-Q  Send-Q  Local Address:Port   Peer Address:Port  Process
LISTEN  0       128     0.0.0.0:22           0.0.0.0:*          users:(("sshd",pid=1234))
LISTEN  0       511     0.0.0.0:80           0.0.0.0:*          users:(("nginx",pid=5678))
LISTEN  0       128     127.0.0.1:3306       0.0.0.0:*          users:(("mysqld",pid=9012))
```

**Practical Application:** Finding which process is using a specific port, checking if your server is listening correctly, identifying unauthorized connections.

---

## 9.5 — `curl` and `wget` (Download/Transfer Data)

### `curl` (Transfer data to/from servers)

```bash
# Fetch a webpage and display it
curl https://example.com

# Download a file (save with the original filename)
curl -O https://example.com/file.tar.gz

# Download and save with a custom filename
curl -o myfile.tar.gz https://example.com/file.tar.gz

# Follow redirects
curl -L https://example.com/redirect

# Show response headers
curl -I https://example.com

# Show detailed connection info (verbose)
curl -v https://example.com

# Send a POST request
curl -X POST -d "name=john&age=30" https://api.example.com/users

# Send JSON data
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"john","age":30}' \
  https://api.example.com/users

# Authenticate
curl -u username:password https://api.example.com/private

# Download silently (no progress bar)
curl -s https://example.com

# Resume a partial download
curl -C - -O https://example.com/largefile.iso

# Upload a file
curl -F "file=@/path/to/myfile.txt" https://example.com/upload

# Test API endpoint and show HTTP status code only
curl -s -o /dev/null -w "%{http_code}" https://example.com
# Output: 200
```

### `wget` (Download files)

```bash
# Download a file
wget https://example.com/file.tar.gz

# Download with a custom filename
wget -O custom_name.tar.gz https://example.com/file.tar.gz

# Download in the background
wget -b https://example.com/largefile.iso

# Resume an interrupted download
wget -c https://example.com/largefile.iso

# Download an entire website (mirror)
wget --mirror --convert-links --page-requisites https://example.com

# Download quietly (no output)
wget -q https://example.com/file.tar.gz

# Limit download speed
wget --limit-rate=500k https://example.com/file.tar.gz

# Download multiple files from a list
wget -i urls.txt
```

---

## 9.6 — `scp` and `rsync` (Secure File Transfer)

### `scp` (Secure Copy over SSH)

```bash
# Copy a local file to a remote server
scp myfile.txt john@192.168.1.100:/home/john/

# Copy a file FROM a remote server to local
scp john@192.168.1.100:/home/john/report.txt ./

# Copy an entire directory (recursive)
scp -r my_project/ john@192.168.1.100:/home/john/

# Use a specific SSH port
scp -P 2222 myfile.txt john@192.168.1.100:/home/john/

# Copy between two remote servers
scp john@server1:/path/file.txt jane@server2:/path/
```

### `rsync` (Advanced Sync — Preferred Over scp)

```bash
# Sync a local directory to a remote server
rsync -avz my_project/ john@192.168.1.100:/home/john/my_project/
# -a = archive mode (preserves permissions, timestamps, etc.)
# -v = verbose
# -z = compress during transfer

# Sync from remote to local
rsync -avz john@192.168.1.100:/home/john/data/ ./local_data/

# Sync with progress bar
rsync -avz --progress source/ destination/

# Delete files at destination that don't exist at source (TRUE mirror)
rsync -avz --delete source/ destination/

# Dry run (show what WOULD happen without actually doing it)
rsync -avzn source/ destination/

# Exclude certain files/patterns
rsync -avz --exclude='*.log' --exclude='.git' source/ destination/

# Sync using SSH on a custom port
rsync -avz -e 'ssh -p 2222' source/ john@server:/path/

# Limit bandwidth usage (in KB/s)
rsync -avz --bwlimit=1000 source/ destination/
```

**Why rsync > scp:**
- Only transfers CHANGES (not the entire file every time)
- Can resume interrupted transfers
- Supports compression
- Can exclude files
- Can delete orphaned files at destination

**Practical Application:** Automated backups, deploying code to servers, keeping two directories in sync.

---

## 9.7 — `ssh` (Secure Shell)

```bash
# Connect to a remote server
ssh john@192.168.1.100

# Connect on a non-standard port
ssh -p 2222 john@192.168.1.100

# Run a single command on a remote server (without opening a shell)
ssh john@192.168.1.100 "uptime"

# Run multiple commands
ssh john@192.168.1.100 "cd /var/log && tail -20 syslog"

# Generate SSH key pair (for passwordless login)
ssh-keygen -t ed25519 -C "john@example.com"
# Or RSA:
ssh-keygen -t rsa -b 4096 -C "john@example.com"

# Copy your public key to a remote server (enable passwordless login)
ssh-copy-id john@192.168.1.100

# SSH with verbose output (debug connection issues)
ssh -v john@192.168.1.100

# SSH tunneling / port forwarding (access remote service locally)
# Forward local port 8080 to remote port 80
ssh -L 8080:localhost:80 john@192.168.1.100

# SSH config file for shortcuts (~/.ssh/config)
```

**Example SSH Config (`~/.ssh/config`):**

```
Host webserver
    HostName 192.168.1.100
    User john
    Port 2222
    IdentityFile ~/.ssh/id_ed25519

Host database
    HostName 10.0.0.50
    User dbadmin
    Port 22
```

Now you can simply type:
```bash
ssh webserver    # Instead of: ssh -p 2222 john@192.168.1.100
ssh database     # Instead of: ssh dbadmin@10.0.0.50
```

---

## 9.8 — DNS and Host Lookup

```bash
# Look up the IP address of a domain
nslookup google.com

# More detailed DNS lookup
dig google.com

# Short answer only
dig +short google.com
# Output: 142.250.80.46

# Reverse DNS lookup (IP to hostname)
dig -x 8.8.8.8

# Look up specific record types
dig google.com MX        # Mail servers
dig google.com NS        # Name servers
dig google.com TXT       # TXT records
dig google.com CNAME     # Canonical name

# Simple hostname lookup
host google.com

# Check /etc/hosts file (local DNS overrides)
cat /etc/hosts

# Check DNS resolver configuration
cat /etc/resolv.conf
```

---

## 9.9 — Firewall Management (`ufw` and `iptables`)

### `ufw` (Uncomplicated Firewall — Ubuntu/Debian)

```bash
# Check status
sudo ufw status
sudo ufw status verbose

# Enable the firewall
sudo ufw enable

# Disable the firewall
sudo ufw disable

# Allow a specific port
sudo ufw allow 22          # Allow SSH
sudo ufw allow 80          # Allow HTTP
sudo ufw allow 443         # Allow HTTPS

# Allow a specific port with protocol
sudo ufw allow 80/tcp

# Allow from a specific IP
sudo ufw allow from 192.168.1.100

# Allow from a specific IP to a specific port
sudo ufw allow from 192.168.1.100 to any port 22

# Deny a port
sudo ufw deny 3306

# Delete a rule
sudo ufw delete allow 80

# Reset all rules
sudo ufw reset

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### `iptables` (Advanced — All Distributions)

```bash
# List all rules
sudo iptables -L -n -v

# Allow incoming SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow incoming HTTP
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Drop all other incoming traffic
sudo iptables -A INPUT -j DROP

# Allow established/related connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Delete a specific rule (by line number)
sudo iptables -L --line-numbers
sudo iptables -D INPUT 3

# Save rules (Debian/Ubuntu)
sudo iptables-save > /etc/iptables/rules.v4

# Flush all rules (CAREFUL: this removes ALL rules)
sudo iptables -F
```

---

---

# SECTION 10: INPUT/OUTPUT REDIRECTION AND PIPING

This is where Linux becomes incredibly powerful. Redirection and piping let you chain commands together and control where output goes.

---

## 10.1 — Standard Streams

Every Linux process has three standard streams:

| Stream | Number | Default | Description |
|--------|--------|---------|-------------|
| `stdin` | 0 | Keyboard | Standard input |
| `stdout` | 1 | Screen | Standard output (normal output) |
| `stderr` | 2 | Screen | Standard error (error messages) |

---

## 10.2 — Output Redirection (`>` and `>>`)

```bash
# Redirect stdout to a file (OVERWRITES the file)
echo "Hello, World!" > greeting.txt
ls -l /home > file_list.txt

# Redirect stdout to a file (APPENDS to the file)
echo "Another line" >> greeting.txt
date >> logfile.txt

# Redirect ONLY stderr to a file
command_that_might_fail 2> errors.log

# Redirect stdout to one file and stderr to another
command 1> output.log 2> errors.log

# Redirect BOTH stdout and stderr to the same file
command > all_output.log 2>&1
# Or the modern shorthand:
command &> all_output.log

# Append both stdout and stderr
command >> all_output.log 2>&1
# Or:
command &>> all_output.log

# Discard output completely (send to the "black hole")
command > /dev/null           # Discard stdout
command 2> /dev/null          # Discard stderr
command > /dev/null 2>&1      # Discard everything
command &> /dev/null          # Discard everything (shorthand)
```

**Step-by-Step Example:**

```bash
# Save the list of all users to a file
cut -d: -f1 /etc/passwd > all_users.txt

# Append today's date to a log file each time you run it
echo "Backup completed at $(date)" >> backup.log

# Try to list a non-existent directory, capture the error
ls /nonexistent 2> error.log
cat error.log
# Output: ls: cannot access '/nonexistent': No such file or directory
```

---

## 10.3 — Input Redirection (`<`)

```bash
# Feed a file as input to a command
sort < unsorted_names.txt

# Word count from file input
wc -l < myfile.txt

# Send an email using input redirection (if mail is configured)
mail -s "Report" admin@example.com < report.txt
```

---

## 10.4 — Here Documents (`<<`) and Here Strings (`<<<`)

```bash
# Here Document: feed multiple lines of input to a command
cat << EOF
Hello, this is line 1.
This is line 2.
Today's date is $(date).
EOF

# Create a multi-line file
cat << EOF > config.txt
server_name=myapp
port=8080
debug=false
EOF

# Here String: feed a single string as input
wc -w <<< "count the words in this string"
# Output: 7

grep "error" <<< "this has an error message"
# Output: this has an error message
```

---

## 10.5 — Piping (`|`)

**What it does:** Takes the stdout of one command and feeds it as stdin to the next command. This is the heart of the Linux philosophy: small tools chained together.

```bash
# Count how many files are in a directory
ls | wc -l

# Find a specific process
ps aux | grep nginx

# Sort a file and remove duplicates
cat names.txt | sort | uniq

# Find the 5 largest files in a directory
du -sh * | sort -hr | head -5

# Count how many times each word appears in a file
cat book.txt | tr ' ' '\n' | sort | uniq -c | sort -rn | head -20

# Get just IP addresses from network config
ip addr show | grep "inet " | awk '{print $2}'

# Monitor a log file and filter for errors
tail -f /var/log/syslog | grep -i error

# Chain multiple filters
cat /etc/passwd | grep "/bin/bash" | cut -d: -f1 | sort
# This: reads the passwd file
# Then: filters for users who use bash
# Then: extracts just the username
# Then: sorts them alphabetically

# Find running processes, sorted by memory usage
ps aux | sort -k4 -rn | head -10

# Check disk usage and filter for big items
df -h | grep -v "tmpfs" | sort -k5 -rn
```

---

## 10.6 — `tee` (Write to File AND Screen)

**What it does:** Reads from stdin and writes to BOTH stdout (screen) AND a file simultaneously.

```bash
# Display output AND save it to a file
ls -la | tee file_list.txt

# Append instead of overwrite
ls -la | tee -a file_list.txt

# Write to multiple files at once
echo "Important data" | tee file1.txt file2.txt file3.txt

# Use in the middle of a pipeline
cat /var/log/syslog | grep "error" | tee errors.log | wc -l
# This: greps for errors, saves them to errors.log, AND counts them
```

---

## 10.7 — `xargs` (Build Command Lines from Input)

**What it does:** Takes input from a pipe and converts it into arguments for another command.

```bash
# Find all .log files and delete them
find /tmp -name "*.log" | xargs rm

# Safely handle filenames with spaces
find /tmp -name "*.log" -print0 | xargs -0 rm

# Run a command for each line of input
cat urls.txt | xargs -I {} curl -O {}
# {} is replaced by each line from the input

# Limit parallel execution
find . -name "*.jpg" | xargs -P 4 -I {} convert {} -resize 50% small_{}
# -P 4 = run 4 processes in parallel

# Prompt before each execution
echo "file1.txt file2.txt" | xargs -p rm
# Output: rm file1.txt file2.txt?... y

# Pass multiple arguments per command execution
echo "1 2 3 4 5 6" | xargs -n 2 echo
# Output:
# 1 2
# 3 4
# 5 6
```

---

---

# SECTION 11: SEARCH, FIND, AND FILTER

---

## 11.1 — `grep` (Global Regular Expression Print)

**What it does:** Searches for patterns in text. One of the most used commands in Linux.

```bash
# Search for a word in a file
grep "error" logfile.txt

# Case-insensitive search
grep -i "error" logfile.txt

# Search recursively in all files in a directory
grep -r "TODO" /home/john/project/

# Show line numbers
grep -n "error" logfile.txt
# Output: 42:An error occurred at startup

# Show count of matching lines
grep -c "error" logfile.txt
# Output: 7

# Show lines that do NOT match (invert)
grep -v "debug" logfile.txt

# Show filenames only (not the matching lines)
grep -rl "password" /etc/

# Show matching lines with surrounding context
grep -B 3 "error" logfile.txt    # 3 lines Before
grep -A 3 "error" logfile.txt    # 3 lines After
grep -C 3 "error" logfile.txt    # 3 lines of Context (before AND after)

# Search for whole words only (not partial matches)
grep -w "error" logfile.txt
# Matches "error" but NOT "errors" or "terror"

# Use extended regular expressions
grep -E "error|warning|critical" logfile.txt
# Or use egrep:
egrep "error|warning|critical" logfile.txt

# Search for lines starting with a pattern
grep "^root" /etc/passwd

# Search for lines ending with a pattern
grep "bash$" /etc/passwd

# Colorize output (usually default, but explicitly)
grep --color=auto "error" logfile.txt

# Search for a pattern in command output
dmesg | grep -i "usb"
ps aux | grep nginx
history | grep "apt install"
```

**Regular Expression Quick Reference for grep:**

| Pattern | Matches |
|---------|---------|
| `.` | Any single character |
| `*` | Zero or more of the preceding character |
| `^` | Beginning of line |
| `$` | End of line |
| `[abc]` | Any one of a, b, or c |
| `[a-z]` | Any lowercase letter |
| `[0-9]` | Any digit |
| `\b` | Word boundary |
| `+` (with `-E`) | One or more of preceding |
| `?` (with `-E`) | Zero or one of preceding |
| `\|` or `|` (with `-E`) | OR |
| `{n}` (with `-E`) | Exactly n repetitions |

**Step-by-Step Example:**

```bash
# Find all users who use bash shell
grep "/bin/bash$" /etc/passwd
# Output:
# root:x:0:0:root:/root:/bin/bash
# john:x:1000:1000:John Smith:/home/john:/bin/bash

# Find lines containing an IP address pattern
grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" access.log

# Find all function definitions in Python files
grep -rn "def " *.py

# Count ERROR, WARNING, INFO in a log file
grep -c "ERROR" app.log
grep -c "WARNING" app.log
grep -c "INFO" app.log
```

---

## 11.2 — `find` (Search for Files and Directories)

**What it does:** Searches the file system for files and directories matching specified criteria.

```bash
# Find files by name
find /home -name "report.txt"

# Case-insensitive name search
find /home -iname "report.txt"

# Find by file type
find /home -type f          # Regular files only
find /home -type d          # Directories only
find /home -type l          # Symbolic links only

# Find by extension
find /home -name "*.pdf"
find /home -name "*.log"

# Find by size
find / -size +100M          # Larger than 100MB
find / -size -1k            # Smaller than 1KB
find / -size 50M            # Exactly 50MB

# Find by modification time
find /var/log -mtime -7     # Modified in the last 7 days
find /var/log -mtime +30    # Modified MORE than 30 days ago
find /var/log -mmin -60     # Modified in the last 60 minutes

# Find by access time
find /home -atime -1        # Accessed in the last 24 hours

# Find by permissions
find / -perm 777            # Exactly 777
find / -perm -u+x           # At least user execute

# Find by owner
find /home -user john
find /var -group www-data

# Find empty files and directories
find /home -empty

# Find and EXECUTE a command on each result
find /tmp -name "*.tmp" -exec rm {} \;
# {} = placeholder for the found file
# \; = end of the exec command

# Find and execute (more efficient with +)
find /home -name "*.log" -exec ls -lh {} +

# Find and delete (built-in action)
find /tmp -name "*.cache" -delete

# Combine conditions with AND (default) and OR
find /home -name "*.txt" -size +1M                    # AND (implicit)
find /home -name "*.jpg" -o -name "*.png"             # OR
find /home \( -name "*.jpg" -o -name "*.png" \) -size +5M  # OR with AND

# Limit search depth
find /home -maxdepth 2 -name "*.txt"
find /home -mindepth 1 -maxdepth 3 -name "*.conf"

# Find files NOT matching a criteria
find /home -not -name "*.txt"
# Or:
find /home ! -name "*.txt"

# Find recently modified config files
find /etc -name "*.conf" -mtime -1 -ls

# Find executable files
find /usr/bin -type f -executable

# Find files with specific permissions and fix them
find /var/www -type f -perm 777 -exec chmod 644 {} \;
find /var/www -type d -perm 777 -exec chmod 755 {} \;
```

**Practical Examples:**

```bash
# Find all files larger than 500MB on the entire system
sudo find / -type f -size +500M -exec ls -lh {} \; 2>/dev/null

# Find and compress old log files
find /var/log -name "*.log" -mtime +30 -exec gzip {} \;

# Find duplicate files by size (first step)
find /home -type f -exec ls -lS {} + | awk '{print $5, $9}' | sort -n

# Clean up temp files older than 7 days
find /tmp -type f -mtime +7 -delete
```

---

## 11.3 — `locate` (Fast File Search Using Database)

```bash
# First, update the file database
sudo updatedb

# Search for a file
locate report.txt

# Case-insensitive search
locate -i report.txt

# Limit number of results
locate -n 10 "*.conf"

# Count matches
locate -c "*.py"

# Show only existing files (skip deleted files still in database)
locate -e report.txt
```

**`find` vs `locate`:**

| Feature | `find` | `locate` |
|---------|--------|----------|
| Speed | Slower (searches live) | Much faster (uses database) |
| Accuracy | Always current | May be outdated |
| Criteria | Name, size, time, permissions, owner | Name only |
| Actions | Can execute commands on results | Display only |

---

## 11.4 — `awk` (Pattern Scanning and Processing)

**What it does:** A powerful text processing tool that works on columns/fields of data.

```bash
# Print the first column of a file (default delimiter: whitespace)
awk '{print $1}' file.txt

# Print the first and third columns
awk '{print $1, $3}' file.txt

# Print with custom delimiter
awk -F':' '{print $1, $7}' /etc/passwd
# Prints username and shell from /etc/passwd

# Print with formatting
awk -F':' '{printf "User: %-15s Shell: %s\n", $1, $7}' /etc/passwd

# Filter rows (like grep but column-aware)
awk -F':' '$7 == "/bin/bash"' /etc/passwd

# Print lines where column 3 (UID) is greater than 1000
awk -F':' '$3 > 1000 {print $1, $3}' /etc/passwd

# Sum a column of numbers
awk '{sum += $1} END {print "Total:", sum}' numbers.txt

# Count lines matching a pattern
awk '/error/ {count++} END {print count}' logfile.txt

# Print the last column (variable number of fields)
awk '{print $NF}' file.txt

# Print line numbers
awk '{print NR, $0}' file.txt

# Process CSV files
awk -F',' '{print $1, $3}' data.csv

# Multiple conditions
awk -F':' '$3 >= 1000 && $7 != "/usr/sbin/nologin" {print $1}' /etc/passwd

# BEGIN and END blocks (run before/after processing)
awk 'BEGIN {print "=== User List ==="} {print $1} END {print "=== Done ==="}' file.txt
```

**Practical Example:**

```bash
# Analyze an Apache access log
# Format: IP - - [date] "request" status size

# Count requests per IP
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10

# Count requests per status code
awk '{print $9}' access.log | sort | uniq -c | sort -rn

# Calculate total data transferred
awk '{sum += $10} END {print sum / 1024 / 1024, "MB"}' access.log
```

---

## 11.5 — `sed` (Stream Editor)

**What it does:** Performs text transformations on a stream of text (find and replace, delete, insert lines).

```bash
# Replace first occurrence on each line
sed 's/old/new/' file.txt

# Replace ALL occurrences on each line (global)
sed 's/old/new/g' file.txt

# Replace case-insensitively
sed 's/old/new/gi' file.txt

# Edit file IN PLACE (modifies the original file)
sed -i 's/old/new/g' file.txt

# Edit in place with backup
sed -i.bak 's/old/new/g' file.txt
# Creates file.txt.bak before modifying file.txt

# Delete lines matching a pattern
sed '/pattern/d' file.txt

# Delete blank lines
sed '/^$/d' file.txt

# Delete line 5
sed '5d' file.txt

# Delete lines 3 through 7
sed '3,7d' file.txt

# Print only matching lines (like grep)
sed -n '/pattern/p' file.txt

# Insert a line BEFORE line 3
sed '3i\This is inserted before line 3' file.txt

# Insert a line AFTER line 3
sed '3a\This is inserted after line 3' file.txt

# Replace only on specific lines
sed '5s/old/new/g' file.txt         # Only on line 5
sed '1,10s/old/new/g' file.txt      # Lines 1-10

# Multiple operations
sed -e 's/foo/bar/g' -e 's/baz/qux/g' file.txt

# Using different delimiters (useful when text contains /)
sed 's|/usr/local/bin|/opt/bin|g' file.txt
sed 's#old/path#new/path#g' file.txt
```

**Practical Examples:**

```bash
# Change a configuration value
sed -i 's/port=8080/port=9090/' config.conf

# Remove comment lines (lines starting with #)
sed '/^#/d' config.conf

# Add a prefix to every line
sed 's/^/[LOG] /' logfile.txt

# Convert Windows line endings to Unix
sed -i 's/\r$//' file.txt

# Replace only on lines containing a specific pattern
sed '/server/s/localhost/192.168.1.100/g' config.conf
```

---

---

# SECTION 12: COMPRESSION AND ARCHIVING

---

## 12.1 — `tar` (Tape Archive)

```bash
# CREATE an archive (no compression)
tar -cvf archive.tar folder/
# -c = create
# -v = verbose (show files being added)
# -f = filename of the archive

# CREATE a gzip-compressed archive (.tar.gz or .tgz)
tar -czvf archive.tar.gz folder/
# -z = gzip compression

# CREATE a bzip2-compressed archive (.tar.bz2) — better compression, slower
tar -cjvf archive.tar.bz2 folder/
# -j = bzip2 compression

# CREATE an xz-compressed archive (.tar.xz) — best compression, slowest
tar -cJvf archive.tar.xz folder/
# -J = xz compression

# EXTRACT an archive
tar -xvf archive.tar              # Uncompressed
tar -xzvf archive.tar.gz          # gzip
tar -xjvf archive.tar.bz2         # bzip2
tar -xJvf archive.tar.xz          # xz

# Extract to a specific directory
tar -xzvf archive.tar.gz -C /destination/directory/

# LIST contents of an archive (without extracting)
tar -tzvf archive.tar.gz

# Add files to an existing tar (uncompressed only)
tar -rvf archive.tar newfile.txt

# Extract a specific file from an archive
tar -xzvf archive.tar.gz path/to/specific/file.txt

# Exclude files from archive
tar -czvf archive.tar.gz folder/ --exclude='*.log' --exclude='.git'

# Create archive with date in filename
tar -czvf backup_$(date +%Y%m%d).tar.gz /home/john/project/
```

---

## 12.2 — `gzip`, `bzip2`, `xz` (Individual File Compression)

```bash
# Compress a file with gzip (replaces original)
gzip largefile.txt
# Creates: largefile.txt.gz (original is deleted)

# Decompress
gunzip largefile.txt.gz
# Or:
gzip -d largefile.txt.gz

# Keep the original file
gzip -k largefile.txt

# Compress with maximum compression
gzip -9 largefile.txt

# Compress with bzip2 (better compression)
bzip2 largefile.txt
bunzip2 largefile.txt.bz2

# Compress with xz (best compression)
xz largefile.txt
unxz largefile.txt.xz

# View compressed file without decompressing
zcat file.txt.gz
bzcat file.txt.bz2
xzcat file.txt.xz

# Grep through compressed files
zgrep "error" logfile.gz
```

---

## 12.3 — `zip` and `unzip`

```bash
# Create a zip archive
zip archive.zip file1.txt file2.txt

# Zip a directory
zip -r archive.zip folder/

# Zip with password protection
zip -e secure_archive.zip sensitive_data.txt

# Unzip
unzip archive.zip

# Unzip to a specific directory
unzip archive.zip -d /destination/

# List contents without extracting
unzip -l archive.zip

# Overwrite without prompting
unzip -o archive.zip

# Unzip specific files
unzip archive.zip "*.txt"
```

**Compression Comparison:**

| Format | Speed | Compression | Command |
|--------|-------|-------------|---------|
| gzip | Fast | Good | `tar -czvf` |
| bzip2 | Medium | Better | `tar -cjvf` |
| xz | Slow | Best | `tar -cJvf` |
| zip | Fast | Good | `zip -r` |

---

---

# SECTION 13: SHELL SCRIPTING

Shell scripting is how you automate tasks in Linux. A shell script is a text file containing a series of commands that the shell can execute.

---

## 13.1 — Your First Shell Script

```bash
# Step 1: Create the script file
nano my_first_script.sh

# Step 2: Add the following content:
```

```bash
#!/bin/bash
# This is a comment — the line above is called a "shebang"
# The shebang tells the system to use bash to interpret this script

# Print a greeting
echo "Hello! Welcome to shell scripting."
echo "Today's date is: $(date)"
echo "You are logged in as: $(whoami)"
echo "Your current directory is: $(pwd)"
```

```bash
# Step 3: Make it executable
chmod +x my_first_script.sh

# Step 4: Run it
./my_first_script.sh

# Alternative: run without making it executable
bash my_first_script.sh
```

**Output:**

```
Hello! Welcome to shell scripting.
Today's date is: Tue Oct 15 14:30:25 UTC 2024
You are logged in as: john
Your current directory is: /home/john
```

---

## 13.2 — Variables

```bash
#!/bin/bash

# Defining variables (NO SPACES around the = sign!)
name="John"
age=30
current_dir=$(pwd)            # Command substitution
file_count=$(ls | wc -l)      # Store command output in a variable

# Using variables (prefix with $)
echo "Name: $name"
echo "Age: $age"
echo "Current directory: $current_dir"
echo "Files in this directory: $file_count"

# Using variables inside strings (curly braces for clarity)
echo "Hello, ${name}! You are ${age} years old."

# This is IMPORTANT when appending text:
echo "${name}_backup"     # Correct: John_backup
echo "$name_backup"       # WRONG: treats $name_backup as the variable name

# Read-only variables (constants)
readonly PI=3.14159
PI=3.14    # This would cause an error!

# Unsetting a variable
my_var="temporary"
unset my_var

# Environment variables (available to child processes)
export DATABASE_URL="localhost:5432/mydb"
export API_KEY="abc123"
```

---

## 13.3 — User Input

```bash
#!/bin/bash

# Basic input
echo "What is your name?"
read name
echo "Hello, $name!"

# Input with prompt on the same line
read -p "Enter your age: " age
echo "You are $age years old."

# Silent input (for passwords)
read -sp "Enter your password: " password
echo    # Print a newline after hidden input
echo "Password received (${#password} characters)"

# Input with a default value
read -p "Enter directory [/home]: " directory
directory=${directory:-/home}     # Use /home if empty
echo "Using directory: $directory"

# Input with a time limit (5 seconds)
read -t 5 -p "Quick! Enter a number: " number

# Read multiple values
read -p "Enter first and last name: " first last
echo "First: $first, Last: $last"
```

---

## 13.4 — Command Line Arguments

```bash
#!/bin/bash
# Save as: greet.sh
# Usage: ./greet.sh John 30

echo "Script name: $0"           # The script itself
echo "First argument: $1"        # John
echo "Second argument: $2"       # 30
echo "All arguments: $@"         # John 30
echo "Number of arguments: $#"   # 2
echo "All arguments as one string: $*"

# Practical example
if [ $# -lt 2 ]; then
    echo "Usage: $0 <name> <age>"
    exit 1
fi

echo "Hello, $1! You are $2 years old."
```

```bash
# Running it:
./greet.sh John 30
# Output:
# Script name: ./greet.sh
# First argument: John
# Second argument: 30
# Hello, John! You are 30 years old.
```

---

## 13.5 — Conditional Statements (if/else)

```bash
#!/bin/bash

# Basic if/else
age=25

if [ $age -ge 18 ]; then
    echo "You are an adult."
else
    echo "You are a minor."
fi

# if / elif / else
score=85

if [ $score -ge 90 ]; then
    echo "Grade: A"
elif [ $score -ge 80 ]; then
    echo "Grade: B"
elif [ $score -ge 70 ]; then
    echo "Grade: C"
elif [ $score -ge 60 ]; then
    echo "Grade: D"
else
    echo "Grade: F"
fi
```

### Comparison Operators

**Integer Comparisons:**

| Operator | Meaning | Example |
|----------|---------|---------|
| `-eq` | Equal | `[ $a -eq $b ]` |
| `-ne` | Not equal | `[ $a -ne $b ]` |
| `-gt` | Greater than | `[ $a -gt $b ]` |
| `-lt` | Less than | `[ $a -lt $b ]` |
| `-ge` | Greater or equal | `[ $a -ge $b ]` |
| `-le` | Less or equal | `[ $a -le $b ]` |

**String Comparisons:**

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` or `==` | Equal | `[ "$a" = "$b" ]` |
| `!=` | Not equal | `[ "$a" != "$b" ]` |
| `-z` | String is empty | `[ -z "$a" ]` |
| `-n` | String is NOT empty | `[ -n "$a" ]` |

**File Tests:**

| Operator | Meaning | Example |
|----------|---------|---------|
| `-f` | File exists and is regular file | `[ -f "/path/file" ]` |
| `-d` | Directory exists | `[ -d "/path/dir" ]` |
| `-e` | File/directory exists | `[ -e "/path/item" ]` |
| `-r` | File is readable | `[ -r "/path/file" ]` |
| `-w` | File is writable | `[ -w "/path/file" ]` |
| `-x` | File is executable | `[ -x "/path/file" ]` |
| `-s` | File exists and is not empty | `[ -s "/path/file" ]` |
| `-L` | File is a symbolic link | `[ -L "/path/file" ]` |

**Logical Operators:**

| Operator | Meaning | Example |
|----------|---------|---------|
| `-a` or `&&` | AND | `[ $a -gt 0 ] && [ $a -lt 100 ]` |
| `-o` or `\|\|` | OR | `[ $a -eq 0 ] \|\| [ $a -eq 1 ]` |
| `!` | NOT | `[ ! -f "file.txt" ]` |

### Practical Examples

```bash
#!/bin/bash

# Check if a file exists before processing
file="/etc/nginx/nginx.conf"

if [ -f "$file" ]; then
    echo "Nginx config found. Lines: $(wc -l < "$file")"
else
    echo "Nginx is not installed or config is missing."
fi

# Check if a directory exists, create it if not
backup_dir="/home/john/backups"

if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
    echo "Created backup directory: $backup_dir"
else
    echo "Backup directory already exists."
fi

# Check if a command exists
if command -v docker &> /dev/null; then
    echo "Docker is installed: $(docker --version)"
else
    echo "Docker is NOT installed."
fi

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Running as root."
else
    echo "This script requires root privileges. Use sudo."
    exit 1
fi

# String comparison
read -p "Continue? (yes/no): " answer
if [ "$answer" = "yes" ]; then
    echo "Proceeding..."
else
    echo "Cancelled."
    exit 0
fi
```

### Using `[[ ]]` (Modern Bash — Preferred)

```bash
#!/bin/bash

# [[ ]] is more powerful and safer than [ ]
name="John Smith"

# Pattern matching with ==
if [[ "$name" == J* ]]; then
    echo "Name starts with J"
fi

# Regular expression matching with =~
email="john@example.com"
if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Valid email format"
fi

# No need to quote variables (safer)
if [[ -z $possibly_empty ]]; then
    echo "Variable is empty"
fi

# Combine conditions more naturally
age=25
name="John"
if [[ $age -ge 18 && $name == "John" ]]; then
    echo "Adult John found!"
fi
```

---

## 13.6 — Case Statements

```bash
#!/bin/bash

read -p "Enter a fruit: " fruit

case $fruit in
    "apple")
        echo "Apples are red or green."
        ;;
    "banana")
        echo "Bananas are yellow."
        ;;
    "orange" | "tangerine")
        echo "These are citrus fruits."
        ;;
    *)
        echo "I don't know about $fruit."
        ;;
esac

# Practical example: service management script
#!/bin/bash

case $1 in
    start)
        echo "Starting service..."
        systemctl start myapp
        ;;
    stop)
        echo "Stopping service..."
        systemctl stop myapp
        ;;
    restart)
        echo "Restarting service..."
        systemctl restart myapp
        ;;
    status)
        systemctl status myapp
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
```

---

## 13.7 — Loops

### For Loops

```bash
#!/bin/bash

# Loop through a list
for color in red green blue yellow; do
    echo "Color: $color"
done

# Loop through a range of numbers
for i in {1..10}; do
    echo "Number: $i"
done

# Loop with a step
for i in {0..100..10}; do
    echo "Count: $i"
done
# Output: 0, 10, 20, 30, ... 100

# C-style for loop
for ((i=1; i<=5; i++)); do
    echo "Iteration: $i"
done

# Loop through files
for file in *.txt; do
    echo "Processing: $file"
    wc -l "$file"
done

# Loop through command output
for user in $(cut -d: -f1 /etc/passwd); do
    echo "User: $user"
done

# Loop through lines of a file
while IFS= read -r line; do
    echo "Line: $line"
done < myfile.txt

# Practical: rename all .txt files to .bak
for file in *.txt; do
    mv "$file" "${file%.txt}.bak"
    echo "Renamed $file to ${file%.txt}.bak"
done

# Practical: batch resize images
for img in *.jpg; do
    convert "$img" -resize 50% "thumb_${img}"
    echo "Created thumbnail for $img"
done
```

### While Loops

```bash
#!/bin/bash

# Basic while loop
count=1
while [ $count -le 5 ]; do
    echo "Count: $count"
    ((count++))
done

# Infinite loop (use Ctrl+C to stop, or break)
while true; do
    echo "Monitoring... (Press Ctrl+C to stop)"
    df -h / | tail -1
    sleep 5
done

# Read file line by line (PROPER way)
while IFS= read -r line; do
    echo "Processing: $line"
done < input.txt

# Menu-driven program
while true; do
    echo ""
    echo "=== System Menu ==="
    echo "1. Show disk usage"
    echo "2. Show memory usage"
    echo "3. Show logged-in users"
    echo "4. Exit"
    read -p "Choose an option: " choice

    case $choice in
        1) df -h ;;
        2) free -h ;;
        3) who ;;
        4) echo "Goodbye!"; break ;;
        *) echo "Invalid option" ;;
    esac
done

# Process monitoring loop
while true; do
    if ! pgrep -x "nginx" > /dev/null; then
        echo "$(date): Nginx is DOWN! Restarting..."
        sudo systemctl start nginx
    fi
    sleep 30
done
```

### Until Loops

```bash
#!/bin/bash

# Until loop (runs until condition becomes TRUE)
count=1
until [ $count -gt 5 ]; do
    echo "Count: $count"
    ((count++))
done

# Wait for a server to come online
until ping -c 1 192.168.1.100 &> /dev/null; do
    echo "Waiting for server to respond..."
    sleep 5
done
echo "Server is online!"
```

---

## 13.8 — Functions

```bash
#!/bin/bash

# Define a function
greet() {
    echo "Hello, $1! Welcome to $2."
}

# Call the function
greet "John" "Linux"
# Output: Hello, John! Welcome to Linux.

# Function with return value
is_even() {
    if [ $(($1 % 2)) -eq 0 ]; then
        return 0    # 0 = success/true in bash
    else
        return 1    # non-zero = failure/false
    fi
}

# Using the return value
if is_even 42; then
    echo "42 is even"
fi

# Function that outputs a value (use echo + command substitution)
get_disk_usage() {
    df -h / | awk 'NR==2 {print $5}'
}

usage=$(get_disk_usage)
echo "Disk usage: $usage"

# Function with local variables
calculate_area() {
    local length=$1     # 'local' keeps the variable inside the function
    local width=$2
    local area=$((length * width))
    echo $area
}

result=$(calculate_area 5 10)
echo "Area: $result square units"

# Practical function: create a timestamped backup
backup() {
    local source=$1
    local dest_dir=${2:-/tmp/backups}    # Default destination
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local basename=$(basename "$source")

    mkdir -p "$dest_dir"
    cp -r "$source" "${dest_dir}/${basename}_${timestamp}"
    echo "Backup created: ${dest_dir}/${basename}_${timestamp}"
}

backup /etc/nginx /home/john/backups
# Output: Backup created: /home/john/backups/nginx_20241015_143025

# Practical function: logging
log() {
    local level=$1
    shift   # Remove first argument, remaining args become the message
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a /var/log/myscript.log
}

log "INFO" "Script started"
log "WARNING" "Disk usage above 80%"
log "ERROR" "Database connection failed"
```

---

## 13.9 — Arrays

```bash
#!/bin/bash

# Define an array
fruits=("apple" "banana" "cherry" "date" "elderberry")

# Access elements (zero-indexed)
echo "${fruits[0]}"         # apple
echo "${fruits[2]}"         # cherry

# Access all elements
echo "${fruits[@]}"         # apple banana cherry date elderberry

# Get array length
echo "${#fruits[@]}"        # 5

# Get length of a specific element
echo "${#fruits[1]}"        # 6 (length of "banana")

# Loop through an array
for fruit in "${fruits[@]}"; do
    echo "Fruit: $fruit"
done

# Loop with index
for i in "${!fruits[@]}"; do
    echo "Index $i: ${fruits[$i]}"
done

# Add an element
fruits+=("fig")

# Remove an element
unset fruits[1]             # Removes "banana"

# Slice an array (elements 1-3)
echo "${fruits[@]:1:3}"

# Practical: store server list
servers=("web01" "web02" "db01" "cache01")

for server in "${servers[@]}"; do
    echo "Pinging $server..."
    if ping -c 1 "$server" &> /dev/null; then
        echo "  ✓ $server is UP"
    else
        echo "  ✗ $server is DOWN"
    fi
done

# Associative arrays (key-value pairs) — Bash 4+
declare -A config
config[host]="localhost"
config[port]="8080"
config[debug]="true"

echo "Host: ${config[host]}"
echo "Port: ${config[port]}"

# Loop through associative array
for key in "${!config[@]}"; do
    echo "$key = ${config[$key]}"
done
```

---

## 13.10 — String Manipulation

```bash
#!/bin/bash

string="Hello, World! Welcome to Linux."

# String length
echo "${#string}"                    # 31

# Substring extraction
echo "${string:0:5}"                 # Hello
echo "${string:7:5}"                 # World

# Find and replace (first occurrence)
echo "${string/World/Earth}"         # Hello, Earth! Welcome to Linux.

# Find and replace (ALL occurrences)
echo "${string//l/L}"                # HeLLo, WorLd! WeLcome to Linux.

# Remove from beginning (shortest match)
filename="document.backup.tar.gz"
echo "${filename#*.}"                # backup.tar.gz

# Remove from beginning (longest match)
echo "${filename##*.}"               # gz

# Remove from end (shortest match)
echo "${filename%.*}"                # document.backup.tar

# Remove from end (longest match)
echo "${filename%%.*}"               # document

# Default values
echo "${undefined_var:-default}"     # default (if var is unset/empty)
echo "${undefined_var:=default}"     # default AND sets the variable

# Convert case (Bash 4+)
name="john smith"
echo "${name^^}"                     # JOHN SMITH (uppercase)
echo "${name^}"                      # John smith (capitalize first)

name="JOHN SMITH"
echo "${name,,}"                     # john smith (lowercase)
echo "${name,}"                      # jOHN SMITH (lowercase first)

# Practical: extract file extension
filepath="/home/john/photo.jpg"
extension="${filepath##*.}"
filename="${filepath##*/}"
directory="${filepath%/*}"
name_only="${filename%.*}"

echo "Full path:  $filepath"
echo "Directory:  $directory"
echo "Filename:   $filename"
echo "Name only:  $name_only"
echo "Extension:  $extension"
```

---

## 13.11 — Error Handling

```bash
#!/bin/bash

# Exit immediately on any error
set -e

# Exit on undefined variables
set -u

# Catch errors in pipes
set -o pipefail

# Combine all three (recommended for robust scripts)
set -euo pipefail

# Custom error handling with trap
cleanup() {
    echo "Error occurred on line $1"
    echo "Cleaning up temporary files..."
    rm -f /tmp/mytempfile_*
    exit 1
}

trap 'cleanup $LINENO' ERR

# Try/catch equivalent using || (OR operator)
mkdir /some/directory 2>/dev/null || {
    echo "Failed to create directory. Trying with sudo..."
    sudo mkdir -p /some/directory || {
        echo "Fatal: Cannot create directory even with sudo."
        exit 1
    }
}

# Check command exit status
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    exit 1
fi

# Exit codes
# 0 = success
# 1 = general error
# 2 = misuse of command
# 126 = permission denied
# 127 = command not found
# 130 = Ctrl+C

# Custom exit codes
check_disk_space() {
    local usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$usage" -gt 90 ]; then
        echo "CRITICAL: Disk usage at ${usage}%"
        return 2
    elif [ "$usage" -gt 80 ]; then
        echo "WARNING: Disk usage at ${usage}%"
        return 1
    else
        echo "OK: Disk usage at ${usage}%"
        return 0
    fi
}

check_disk_space
status=$?
echo "Exit code: $status"
```

---

## 13.12 — Complete Practical Script Examples

### Example 1: System Health Check Script

```bash
#!/bin/bash
#============================================
# System Health Check Script
# Usage: ./health_check.sh
#============================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Thresholds
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80

echo "============================================"
echo "   System Health Check - $(date)"
echo "============================================"
echo ""

# 1. System Information
echo -e "${GREEN}[System Info]${NC}"
echo "Hostname:    $(hostname)"
echo "OS:          $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel:      $(uname -r)"
echo "Uptime:      $(uptime -p)"
echo ""

# 2. CPU Usage
echo -e "${GREEN}[CPU Usage]${NC}"
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)
if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
    echo -e "CPU Usage: ${RED}${cpu_usage}% — HIGH!${NC}"
else
    echo -e "CPU Usage: ${GREEN}${cpu_usage}%${NC}"
fi
echo ""

# 3. Memory Usage
echo -e "${GREEN}[Memory Usage]${NC}"
mem_total=$(free -m | awk 'NR==2{print $2}')
mem_used=$(free -m | awk 'NR==2{print $3}')
mem_percent=$((mem_used * 100 / mem_total))

if [ "$mem_percent" -gt "$MEM_THRESHOLD" ]; then
    echo -e "Memory: ${RED}${mem_used}MB / ${mem_total}MB (${mem_percent}%) — HIGH!${NC}"
else
    echo -e "Memory: ${GREEN}${mem_used}MB / ${mem_total}MB (${mem_percent}%)${NC}"
fi
echo ""

# 4. Disk Usage
echo -e "${GREEN}[Disk Usage]${NC}"
while IFS= read -r line; do
    usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')
    size=$(echo "$line" | awk '{print $2}')
    used=$(echo "$line" | awk '{print $3}')

    if [ "$usage" -gt "$DISK_THRESHOLD" ]; then
        echo -e "  ${mount}: ${RED}${used}/${size} (${usage}%) — HIGH!${NC}"
    else
        echo -e "  ${mount}: ${GREEN}${used}/${size} (${usage}%)${NC}"
    fi
done < <(df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs | tail -n +2)
echo ""

# 5. Top 5 Processes by CPU
echo -e "${GREEN}[Top 5 Processes by CPU]${NC}"
ps aux --sort=-%cpu | head -6 | awk '{printf "  %-10s %5s%% CPU  %5s%% MEM  %s\n", $1, $3, $4, $11}'
echo ""

# 6. Top 5 Processes by Memory
echo -e "${GREEN}[Top 5 Processes by Memory]${NC}"
ps aux --sort=-%mem | head -6 | awk '{printf "  %-10s %5s%% MEM  %5s%% CPU  %s\n", $1, $4, $3, $11}'
echo ""

# 7. Network
echo -e "${GREEN}[Network]${NC}"
echo "Active connections: $(ss -tun | wc -l)"
echo "Listening ports:    $(ss -tlun | tail -n +2 | wc -l)"
echo ""

echo "============================================"
echo "   Health check complete!"
echo "============================================"
```

### Example 2: Automated Backup Script

```bash
#!/bin/bash
#============================================
# Automated Backup Script
# Usage: ./backup.sh /path/to/source [/path/to/destination]
#============================================

set -euo pipefail

# Configuration
SOURCE="${1:?Usage: $0 <source_directory> [destination_directory]}"
DEST="${2:-/home/$(whoami)/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$DEST/backup.log"
MAX_BACKUPS=7    # Keep last 7 backups

# Functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Validate source
if [ ! -d "$SOURCE" ]; then
    echo "Error: Source directory '$SOURCE' does not exist."
    exit 1
fi

# Create destination if needed
mkdir -p "$DEST"

# Get source directory name
SOURCE_NAME=$(basename "$SOURCE")
BACKUP_FILE="${DEST}/${SOURCE_NAME}_${TIMESTAMP}.tar.gz"

# Perform backup
log "Starting backup of '$SOURCE'..."
log "Destination: $BACKUP_FILE"

tar -czvf "$BACKUP_FILE" -C "$(dirname "$SOURCE")" "$SOURCE_NAME" 2>> "$LOG_FILE"

# Verify backup was created
if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
    log "Backup successful! Size: $SIZE"
else
    log "ERROR: Backup failed!"
    exit 1
fi

# Rotate old backups (keep only MAX_BACKUPS)
BACKUP_COUNT=$(ls -1 "${DEST}/${SOURCE_NAME}_"*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    log "Rotating old backups (keeping last $MAX_BACKUPS)..."
    ls -1t "${DEST}/${SOURCE_NAME}_"*.tar.gz | tail -n +$((MAX_BACKUPS + 1)) | while read -r old_backup; do
        log "  Removing: $(basename "$old_backup")"
        rm "$old_backup"
    done
fi

log "Backup complete!"
echo ""
echo "Summary:"
echo "  Source:      $SOURCE"
echo "  Backup:      $BACKUP_FILE"
echo "  Size:        $SIZE"
echo "  Total backups: $(ls -1 "${DEST}/${SOURCE_NAME}_"*.tar.gz 2>/dev/null | wc -l)"
```

### Example 3: Log Analyzer Script

```bash
#!/bin/bash
#============================================
# Log File Analyzer
# Usage: ./log_analyzer.sh <logfile>
#============================================

LOG_FILE="${1:?Usage: $0 <logfile>}"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: File '$LOG_FILE' not found."
    exit 1
fi

echo "======================================="
echo "   Log Analysis: $(basename "$LOG_FILE")"
echo "   Generated: $(date)"
echo "======================================="
echo ""

# Total lines
total=$(wc -l < "$LOG_FILE")
echo "Total log entries: $total"
echo ""

# Count by log level
echo "--- Entries by Log Level ---"
for level in ERROR WARNING INFO DEBUG; do
    count=$(grep -ci "$level" "$LOG_FILE" 2>/dev/null || echo 0)
    percentage=0
    if [ "$total" -gt 0 ]; then
        percentage=$((count * 100 / total))
    fi
    printf "  %-10s %6d  (%d%%)\n" "$level" "$count" "$percentage"
done
echo ""

# Top 10 most frequent error messages
error_count=$(grep -ci "error" "$LOG_FILE" 2>/dev/null || echo 0)
if [ "$error_count" -gt 0 ]; then
    echo "--- Top 10 Error Messages ---"
    grep -i "error" "$LOG_FILE" | sort | uniq -c | sort -rn | head -10 | while read -r count msg; do
        echo "  [$count] $msg"
    done
    echo ""
fi

# Activity by hour (if timestamps are in standard format)
echo "--- Activity by Hour ---"
grep -oP '\d{2}:\d{2}:\d{2}' "$LOG_FILE" 2>/dev/null | cut -d: -f1 | sort | uniq -c | sort -k2n | while read -r count hour; do
    bar=$(printf '%*s' "$((count / 10))" '' | tr ' ' '█')
    printf "  %s:00  %5d  %s\n" "$hour" "$count" "$bar"
done
echo ""

echo "Analysis complete!"
```

---

---

# SECTION 14: CRON JOBS AND TASK SCHEDULING

---

## 14.1 — `crontab` (Schedule Recurring Tasks)

```bash
# View your current crontab
crontab -l

# Edit your crontab
crontab -e

# Remove your crontab (deletes ALL your cron jobs)
crontab -r

# View another user's crontab (requires root)
sudo crontab -l -u john

# Edit another user's crontab
sudo crontab -e -u john
```

### Crontab Format

```
* * * * * command_to_run
│ │ │ │ │
│ │ │ │ └── Day of week (0-7, where 0 and 7 = Sunday)
│ │ │ └──── Month (1-12)
│ │ └────── Day of month (1-31)
│ └──────── Hour (0-23)
└────────── Minute (0-59)
```

### Common Cron Schedules

```bash
# Every minute
* * * * * /path/to/script.sh

# Every 5 minutes
*/5 * * * * /path/to/script.sh

# Every hour (at minute 0)
0 * * * * /path/to/script.sh

# Every day at midnight
0 0 * * * /path/to/script.sh

# Every day at 2:30 AM
30 2 * * * /path/to/script.sh

# Every Monday at 9 AM
0 9 * * 1 /path/to/script.sh

# Every weekday (Mon-Fri) at 6 PM
0 18 * * 1-5 /path/to/script.sh

# First day of every month at midnight
0 0 1 * * /path/to/script.sh

# Every 15 minutes between 9 AM and 5 PM on weekdays
*/15 9-17 * * 1-5 /path/to/script.sh

# Twice a day (8 AM and 8 PM)
0 8,20 * * * /path/to/script.sh

# Every Sunday at 3 AM (good for weekly maintenance)
0 3 * * 0 /path/to/script.sh
```

### Practical Crontab Examples

```bash
# Edit crontab
crontab -e

# Add these entries:

# Daily backup at 2 AM
0 2 * * * /home/john/scripts/backup.sh >> /var/log/backup.log 2>&1

# Clear tmp directory every Sunday at 4 AM
0 4 * * 0 find /tmp -type f -mtime +7 -delete

# Health check every 5 minutes
*/5 * * * * /home/john/scripts/health_check.sh > /dev/null 2>&1

# Monthly disk usage report on the 1st at 8 AM
0 8 1 * * df -h | mail -s "Monthly Disk Report" admin@example.com

# Renew SSL certificates monthly
0 3 1 * * /usr/bin/certbot renew --quiet

# Database backup every 6 hours
0 */6 * * * /home/john/scripts/db_backup.sh
```

### Special Cron Strings

```bash
@reboot    /path/to/script.sh    # Run once at startup
@yearly    /path/to/script.sh    # Equivalent to: 0 0 1 1 *
@monthly   /path/to/script.sh    # Equivalent to: 0 0 1 * *
@weekly    /path/to/script.sh    # Equivalent to: 0 0 * * 0
@daily     /path/to/script.sh    # Equivalent to: 0 0 * * *
@hourly    /path/to/script.sh    # Equivalent to: 0 * * * *
```

---

## 14.2 — `at` (Schedule a One-Time Task)

```bash
# Schedule a command to run at a specific time
echo "/home/john/scripts/report.sh" | at 10:30 PM

# Schedule for a specific date
echo "backup_script.sh" | at 2:00 AM December 25

# Schedule relative to now
echo "echo 'Reminder!'" | at now + 30 minutes
echo "echo 'Do this'" | at now + 2 hours
echo "echo 'Weekly task'" | at now + 1 week

# Interactive mode
at 10:00 PM
at> /home/john/scripts/backup.sh
at> echo "Backup complete" | mail -s "Done" john@example.com
at> Ctrl+D   (press to save)

# List pending at jobs
atq

# Remove a scheduled job (use job number from atq)
atrm 5

# View details of a pending job
at -c 5
```

---

## 14.3 — `systemd` Timers (Modern Alternative to Cron)

```bash
# List all active timers
systemctl list-timers --all

# View a specific timer
systemctl status apt-daily.timer

# Enable/disable a timer
sudo systemctl enable mybackup.timer
sudo systemctl disable mybackup.timer

# Start/stop a timer
sudo systemctl start mybackup.timer
sudo systemctl stop mybackup.timer
```

Creating a custom systemd timer:

**Service file** (`/etc/systemd/system/mybackup.service`):
```ini
[Unit]
Description=My Backup Service

[Service]
Type=oneshot
ExecStart=/home/john/scripts/backup.sh
User=john
```

**Timer file** (`/etc/systemd/system/mybackup.timer`):
```ini
[Unit]
Description=Run backup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable mybackup.timer
sudo systemctl start mybackup.timer
```

---

---

# SECTION 15: SYSTEM MONITORING AND LOGS

---

## 15.1 — `systemctl` (Service Management)

```bash
# Check status of a service
sudo systemctl status nginx
sudo systemctl status sshd

# Start a service
sudo systemctl start nginx

# Stop a service
sudo systemctl stop nginx

# Restart a service (stop + start)
sudo systemctl restart nginx

# Reload configuration (without stopping)
sudo systemctl reload nginx

# Enable service to start at boot
sudo systemctl enable nginx

# Disable service from starting at boot
sudo systemctl disable nginx

# Check if a service is enabled
systemctl is-enabled nginx

# Check if a service is active (running)
systemctl is-active nginx

# List all services
systemctl list-units --type=service

# List all running services
systemctl list-units --type=service --state=running

# List all failed services
systemctl --failed

# View service logs
journalctl -u nginx

# View recent service logs
journalctl -u nginx --since "1 hour ago"

# Follow service logs in real-time
journalctl -u nginx -f

# Mask a service (prevent it from being started at all)
sudo systemctl mask dangerous-service
sudo systemctl unmask dangerous-service
```

---

## 15.2 — `journalctl` (System Logs with systemd)

```bash
# View ALL system logs
journalctl

# View logs in reverse (newest first)
journalctl -r

# View last 50 lines
journalctl -n 50

# Follow logs in real-time (like tail -f)
journalctl -f

# Filter by time
journalctl --since "2024-10-15 09:00:00"
journalctl --since "1 hour ago"
journalctl --since "yesterday"
journalctl --since "2024-10-01" --until "2024-10-15"

# Filter by priority
journalctl -p err         # Errors and above
journalctl -p warning     # Warnings and above
# Priority levels: emerg, alert, crit, err, warning, notice, info, debug

# Filter by service/unit
journalctl -u sshd
journalctl -u nginx -u mysql    # Multiple services

# Show kernel messages
journalctl -k
journalctl --dmesg

# Show boot logs
journalctl -b             # Current boot
journalctl -b -1           # Previous boot
journalctl --list-boots    # List all boots

# Show disk usage of journal
journalctl --disk-usage

# Clean old logs
sudo journalctl --vacuum-time=7d      # Keep only last 7 days
sudo journalctl --vacuum-size=500M     # Keep only 500MB

# Output in JSON format (useful for parsing)
journalctl -u nginx -o json-pretty

# Filter by PID
journalctl _PID=1234
```

---

## 15.3 — Traditional Log Files

```bash
# Important log files in /var/log/
ls /var/log/

# System log (general system activity)
sudo less /var/log/syslog          # Debian/Ubuntu
sudo less /var/log/messages        # CentOS/RHEL

# Authentication/security log
sudo less /var/log/auth.log        # Debian/Ubuntu
sudo less /var/log/secure          # CentOS/RHEL

# Kernel log
sudo less /var/log/kern.log
dmesg                              # Or use dmesg command

# Package manager log
sudo less /var/log/apt/history.log  # Debian/Ubuntu
sudo less /var/log/dnf.log          # Fedora
sudo less /var/log/yum.log          # CentOS/RHEL

# Boot log
sudo less /var/log/boot.log

# Cron log
sudo less /var/log/cron

# Application-specific logs
sudo less /var/log/nginx/access.log
sudo less /var/log/nginx/error.log
sudo less /var/log/mysql/error.log
sudo less /var/log/apache2/error.log

# Monitor multiple logs simultaneously
sudo tail -f /var/log/syslog /var/log/auth.log

# Search through logs
sudo grep "Failed password" /var/log/auth.log
sudo grep -i "error" /var/log/syslog | tail -20
```

---

## 15.4 — System Information Commands

```bash
# System info overview
uname -a                    # All system info
hostnamectl                 # Hostname and OS info
lsb_release -a              # Distribution info (Debian/Ubuntu)
cat /etc/os-release         # OS details (all distros)

# Hardware info
lscpu                       # CPU information
lsmem                       # Memory layout
lsusb                       # USB devices
lspci                       # PCI devices (graphics card, network, etc.)
lsblk                       # Block devices (disks)
sudo dmidecode               # Detailed hardware info

# System uptime and load
uptime
cat /proc/loadavg

# Memory details
cat /proc/meminfo
free -h

# CPU details
cat /proc/cpuinfo
nproc                       # Number of CPU cores

# Running kernel version
uname -r

# System architecture
arch
# Or:
uname -m

# Environment variables
env                          # Show all
echo $PATH                   # Show specific
echo $HOME
echo $SHELL
echo $USER
```

---

## 15.5 — `vmstat`, `iostat`, `sar` (Performance Monitoring)

```bash
# Virtual memory statistics (updated every 2 seconds, 5 times)
vmstat 2 5

# I/O statistics (requires sysstat package)
sudo apt install sysstat     # Install first

# Disk I/O statistics
iostat

# Detailed disk I/O (every 2 seconds)
iostat -x 2

# System activity reporter
sar -u 2 5                   # CPU usage (every 2 sec, 5 reports)
sar -r 2 5                   # Memory usage
sar -d 2 5                   # Disk I/O
sar -n DEV 2 5               # Network statistics

# Network transfer rates
sudo iftop                   # Interactive network monitor
sudo nethogs                 # Per-process network usage
```

---

---

# 🎓 QUICK REFERENCE CHEAT SHEET

## File Operations
```
ls -la              List all files with details
cd /path            Change directory
cp -r src dst       Copy recursively
mv old new          Move/rename
rm -rf dir          Remove directory (CAREFUL!)
find / -name "*.log"  Find files
```

## Permissions
```
chmod 755 file      Set rwxr-xr-x
chmod u+x file      Add execute for owner
chown user:grp file Change ownership
```

## Process Management
```
ps aux              List all processes
top / htop          Real-time monitoring
kill -9 PID         Force kill process
bg / fg             Background/foreground
```

## Networking
```
ip a                Show IP addresses
ping host           Test connectivity
ss -tlnp            Show listening ports
curl URL            HTTP requests
ssh user@host       Remote connection
```

## Text Processing
```
grep "pattern" file Search text
sed 's/old/new/g'   Find and replace
awk '{print $1}'    Extract columns
sort | uniq -c      Count unique lines
```

## Compression
```
tar -czvf arch.tar.gz dir/    Create .tar.gz
tar -xzvf arch.tar.gz         Extract .tar.gz
```

## System
```
systemctl status svc   Check service
journalctl -u svc -f   Follow service logs
df -h                  Disk space
free -h                Memory usage
```

---

> **Final Advice:** The best way to learn Linux is by **using it daily**. Set up a virtual machine or use Windows Subsystem for Linux (WSL), and practice these commands regularly. Start with basic file operations, then gradually tackle permissions, scripting, and networking. Every expert was once a beginner who refused to give up. Happy learning! 🐧