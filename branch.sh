#!/bin/bash

. repo.sh

get_local_branchs()
{
    local repo_dir=$1
    local branchs=
    
    is_git_repo "${repo_dir}" || return 1
    branchs=$(git branch | awk '{if (NF > 1) {print $2} else {print $1}}')
    if [[ $? -ne 0 ]]; then
        echo "get repo($repo_dir) local branchs failed"
        return 1
    fi

    echo "$branchs"
    return 0
}

get_local_current_branch()
{
    local repo_dir=$1
    local branch_name=

    is_git_repo "${repo_dir}" || return 1

    branch_name=$(git symbolic-ref -q --short HEAD)
    if [[ $? -ne 0 ]]; then
        echo "Get repo(${repo_dir}) current branch name failed"
        return 1
    fi
    
    echo "${branch_name}"

    return 0
}

get_remote_branchs() {
    local repo_dir=$1
    local branchs=
    
    is_git_repo "${repo_dir}" || return 1
    branchs=$(git branch -r -v | awk '{print $1}'| sed 's/^\s*origin\///g')
    if [[ $? -ne 0 ]]; then
        echo "get repo($repo_dir) remote branchs failed"
        return 1
    fi

    echo "$branchs"
    return 0
}

get_parent_branch() {
    local branch_name=$1
    local parent_branch=

    parent_branch=$(git reflog --date=local | grep "$branch_name" | awk '{print $10}')
    if [[ $? -ne 0 || -z $parent_branch ]]; then
        echo "get branch(${branch_name}) parent branch failed"
        return 1
    fi

    echo "${parent_branch}"
    return 0
}

get_commit_files()
{
    local commit_id=$1
    local change_files=

    if [[ -z $commit_id ]]; then
        echo "commit id(${commit_id}) is null"
        return 1
    fi

    change_files=$(git diff --no-merges --name-only "${commit_id}^" "${commit_id}")
    if [[ $? -ne 0 ]]; then
        echo "get commit(${commit_id}) change files failed"
        return 1
    fi

    echo "${change_files}"
    return 0
}

get_commits_between_branchs()
{
    local branch1=$1
    local branch2=$2

    commits=$(git log "${branch2}".."${branch1}" --online --no-merges | awk '{print $1}')
    if [[ $? -ne 0 ]]; then
        echo "get commits between branch(${branch1}) to branch(${branch2}) failed"
        return 1
    fi

    echo "${commits}"
    return 0
}

export -f get_local_branchs
export -f get_local_current_branch
export -f get_remote_branchs
export -f get_parent_branch
export -f get_commit_files
export -f get_commits_between_branchs
