# deploy_agent

`deploy_agent.sh` deploys, runs, and archives the logs of the Student Attendance Tracker
(`attendance_checker.py`). The Python app in `templates/` is never modified.

**Video walkthrough:** https://www.youtube.com/watch?v=x8mfKLTfjpY

## Files

```
deploy_agent.sh      the script
templates/           the three original files (attendance_checker.py, assets.csv, config.json)
```

## How to run it

You need `python3` and `zip` installed.

```bash
chmod +x deploy_agent.sh
./deploy_agent.sh
```

A menu appears. Type the number of the feature you want:

```
1) Deploy
2) Run
3) Archive logs
```

For **Run** and **Archive** the script asks for the project name (e.g. `demo` for
`attendance_tracker_demo`).

## 1) Deploy

1. Checks that `python3` and `zip` are installed and prints the Python version. Stops if either
   is missing.
2. Asks for a project name and creates `attendance_tracker_<name>/` with `Helpers/` and `reports/`.
   If the folder already exists it asks whether to overwrite it. Answering anything other than
   `y` aborts with an error.
3. Copies `attendance_checker.py` and `config.json` from `templates/`, then builds
   `Helpers/assets.csv`:
   - **A**: copies the header and the first N students from `templates/assets.csv`.
   - **B**: generates N new students from a list of names in the script, with all counts at 0.
4. Runs `chmod +x` on `attendance_checker.py` and `chmod 600` on `Helpers/config.json`, then
   prints the permissions.
5. Offers to update the thresholds (see below).
6. Starts the app to show that the deployment works.

### total_sessions

`total_sessions` counts all sessions **including today's**, so it must be one more than the
sessions already in the roster:

- Option A: template students have 4 sessions recorded, so it stays at **5**.
- Option B: new students have 0 sessions, so the script sets it to **1** with `sed`.

## Thresholds

The app warns about students below **warning** (default 75%) and flags students below
**failure** (default 50%) as failing.

If you answer `y` to "Update attendance thresholds?", the script asks for both values. Pressing
Enter keeps the default. Each value must be a whole number from 0 to 100, and failure must be
lower than warning. Otherwise it asks again.

`sed` then changes only the two numbers in the deployed `config.json`:

```bash
sed -i "s/\"warning\": [0-9]*/\"warning\": $warning/" "$config"
sed -i "s/\"failure\": [0-9]*/\"failure\": $failure/" "$config"
```

## 2) Run

Runs the app inside the project folder:

```bash
cd attendance_tracker_<name> && python3 attendance_checker.py
```

The instructor marks each student `p` (present) or `a` (absent). The app writes
`reports/attendance.log`, and `reports/absent.log` if anyone was absent.

## 3) Archive logs

Moves each log into its own folder with a timestamp in its name:

```
attendance_tracker_<name>/archives/attendance/attendance_YYYYMMDD_HHMMSS.log
attendance_tracker_<name>/archives/absent/absent_YYYYMMDD_HHMMSS.log
```

The script prints the path of each archived file. If a log doesn't exist (for example, nobody
was absent, so there is no `absent.log`), it prints `No absent.log found, skipping.` and carries
on.

## Ctrl+C and Ctrl+Z

During deployment the script runs `trap cleanup INT TSTP`. If you press Ctrl+C (SIGINT) or
Ctrl+Z (SIGTSTP), `cleanup`:

1. prints `Deployment interrupted!`
2. zips the unfinished project into `attendance_tracker_<name>_archive.zip`
3. deletes the unfinished folder
4. exits

The trap is removed once deployment finishes, so Ctrl+C while marking is handled by the app.
If you press Ctrl+C at the overwrite question, the existing project is not touched, because the
script has not claimed it yet.

**To test it:** choose `1`, enter a name, press Ctrl+C at the `Roster: (A) ... (B)` question,
then run:

```bash
ls
unzip -l attendance_tracker_<name>_archive.zip
```

The zip contains whatever had been created so far. At the roster question that is
`attendance_checker.py`, `Helpers/config.json` and an empty `reports/`.

## Testing

I tested it on Ubuntu 24.04 by:

- deploying with option A and option B and checking the files with `find` and `cat`
- entering invalid numbers (`abc`, `0`, `150`) and failure ≥ warning to check the validation
- answering `n` and `y` to the overwrite question
- running the app, then archiving with and without an `absent.log`
- pressing Ctrl+C and Ctrl+Z at different prompts and checking the zip with `unzip -l`
