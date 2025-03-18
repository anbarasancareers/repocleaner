#!/bin/bash

## Global Variables
GITHUB_TOKEN="*******************************"  # Set your GitHub token here
REPO_OWNER="********************"   # Set your repo owner name
TIME_WINDOW_DAYS=$((365))  # 1 year
MASTER_REPO_LIST="masterRepoList.txt"      # Repo list 
SUMMARY_FILE="repocleaner_summary.txt"  # Output file 

echo "Cleaning stale branches..." | tee $SUMMARY_FILE


## Function to Delete the branch 
delete_branch() {
    local repo_name=$1
    local branch=$2
    curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
         "https://api.github.com/repos/$REPO_OWNER/$repo_name/git/refs/heads/$branch"
}

## Function to delete the repo
delete_repo() {
    local repo_name=$1
    curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
         "https://api.github.com/repos/$REPO_OWNER/$repo_name"
}

## Function to get the list of branches
get_branches() {
    local repo_name=$1
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
         "https://api.github.com/repos/$REPO_OWNER/$repo_name/branches?per_page=100&page=1" | jq -r '.[].name'
}

## Function to get the latest commit date
get_branch_last_commit_date() {
    local repo_name=$1
    local branch=$2
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
         "https://api.github.com/repos/$REPO_OWNER/$repo_name/commits/$branch" | jq -r '.commit.committer.date'
}

## Function to get the count of branches 
get_total_branches() {
    local repo_name=$1
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
         "https://api.github.com/repos/$REPO_OWNER/$repo_name/branches?per_page=100&page=1" | jq '. | length'
}

## Function to get the list of stale branches
find_stale_branches() {
    local repo_name=$1
    local stale_branches=()
    local current_date=$(date -u +%s)
    
    for branch in $(get_branches "$repo_name" "$REPO_OWNER"); do
        commit_date=$(get_branch_last_commit_date "$repo_name" "$branch" "$REPO_OWNER")
        commit_timestamp=$(date -d "$commit_date" +%s)
        age_days=$(( (current_date - commit_timestamp) / 86400 ))
        
        if [[ $age_days -gt $TIME_WINDOW_DAYS ]]; then
            stale_branches+=("$branch")
        fi
    done
    
    echo "${stale_branches[@]}"
}

## Reading the repo name from the masterRepoList.txt file 
while IFS= read -r repo_name; do            
    echo "Checking repo_name: $repo_name"
    stale_branches=($(find_stale_branches "$repo_name" "$REPO_OWNER"))
    total_branches=($(get_total_branches "$repo_name" "$REPO_OWNER"))
    echo "Total Branches: $total_branches"
    echo "Total Stale Branches: ${#stale_branches[@]}"

    ## If the stale branches not found, loop will continue next repo 
    if [[ ${#stale_branches[@]} -eq 0 ]]; then
        echo "No stale branches found in $repo_name" | tee -a $SUMMARY_FILE
        continue
    fi

    ## If the stale branch count is equal to total branch count of the repo, It will ask confirmation to delete the repo.
    if [[ ${#stale_branches[@]} -eq ${total_branches[@]} ]]; then
        echo "All branches in $repo_name were stale. Consider deleting the repository." | tee -a $SUMMARY_FILE
        read -p "Do you want to delete the repo? : 'yes', or 'no' : " delete_choice < /dev/tty
        if [[ "$delete_choice" == "no" ]]; then
            echo "Skipped the repo deletion: $repo_name" | tee -a $SUMMARY_FILE
            continue
        elif [[ "$delete_choice" == "yes" ]]; then
            delete_repo "$repo_name" "$REPO_OWNER"
            echo "Deleted repo: $repo_name" | tee -a $SUMMARY_FILE
        fi

    ## If the stale branch count is not equal to total branch count of the repo, It will collect branch list and ask confirmation to delete branch.
    elif [[ ${#stale_branches[@]} -ne ${total_branches[@]} ]]; then
        echo "Stale branches found in $repo_name:" 
        for i in "${!stale_branches[@]}"; do
            echo "$((i+1)). ${stale_branches[$i]}"
        done
        
        read -p "Enter numbers of branches to delete (comma-separated), or 'all', or 'none': " choices < /dev/tty
        
        ## based on the user input, if the choice is none/empty it will not delete listed stale branches 
        if [[ "$choices" == "none" ]]; then
            continue
        
        ## based on the user input, if the choice is all, it will delete all listed stale branches  
        elif [[ "$choices" == "all" ]]; then
            to_delete=("${stale_branches[@]}")
        
        ## based on the user input, if the choice is comma seperated inputs (example: 1,2,3), it will delete mentioned stale branches 
        else
            IFS=',' read -r -a indices <<< "$choices"
            to_delete=()
            for index in "${indices[@]}"; do
                to_delete+=("${stale_branches[$((index-1))]}")
            done
        fi

        ## Deletes the stale branches based on the user input
        for branch in "${to_delete[@]}"; do
            delete_branch "$repo_name" "$branch"
            echo "Deleted Branch: $repo_name/$branch" | tee -a $SUMMARY_FILE
        done
    fi

done < "$MASTER_REPO_LIST"

echo "Summary saved to $SUMMARY_FILE"