# RepoCleaner: Stale Branch Cleanup Utility

## Overview
repocleaner.sh is a Bash script that identifies and deletes stale branches in GitHub repositories. It reads a list of repositories from a file, finds branches that haven't been updated for over a year, and provides an option to delete them. If all branches in a repository are stale, it suggests deleting the repository.

## Functionalities
- Reads repository names from masterRepoList.txt.
- Fetches all branches in each repository.
- Identifies stale branches (older than 1 year).
- Asks the user for confirmation before deletion.
- Deletes the selected branches.
- If all branches are stale, suggests deleting the repository.
- Generates a summary of deleted branches and repositories.

## Prerequisites
- A GitHub Personal Access Token with repo access.
- Installed dependencies: `jq` (to parse JSON responses from GitHub API)
- Installed dependencies: `curl` installed for making API requests.
- A file masterRepoList.txt containing repository names (one per line).





** Explained each function, execution and use cases with screenshot in below document **

https://docs.google.com/document/d/1hWiBvy43tvjG9c8tMPOgQIyaTBL86Lgc0sUhs56NMjQ/edit?usp=sharing
