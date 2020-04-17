# Purpose:
```.
Automate restic backup to B2 cloud storage
```

# Files:
```.
README.md         :Describes project purpose, files, function, and setup
.excludes         :Don't backup these paths and files.
.includes         :Do backup these paths and files.
.resticrc.example :Template for creating .resticrc 
restic_run.bash   :Work horse script
```

# Setup:
```.
Collect needed info for .resticrc:
Visit: https://secure.backblaze.com
- Create B2 cloud storage account
- Buckets-> Create B2 Bucket -> Type Private -> Name bucket
  RESTIC_REPOSITORY == bucket name
- App Keys -> Master Application Key
  B2_ACCOUNT_ID == keyID 
  B2_ACCOUNT_KEY == Click "Generate New Master Application Key"
  RESTIC_PASSWORD= == your B2 account password

cp .resticrc.example .resticrc
Edit .resticrc 
Change RESTIC_REPOSITORY, B2_ACCOUNT_ID, B2_ACCOUNT_KEY, B2_ACCOUNT_PASSWORD

Before your first backup initialize Bucket
./restic_run.bash init

For each backup:
./restic_run.bash  backup 

# Setup crontab
crontab -e
# Restic backup to B2 storage
0    *    *    *     *  /root/restic/restic_run.bash -a backup 2>&1 | tee -a /root/restic/backup.log
```

## References:
B2 Quick Setup: https://www.backblaze.com/b2/docs/quick_account.html
Restic doc:  https://restic.readthedocs.io/en/latest/
