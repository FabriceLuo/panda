#!/bin/bash

get_local_branchs()
{
    local repo_dir=$1
    local branchs=
    
    is_git_repo "${repo_dir}" || return 1
    branchs=$(git branch)
    
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

is_git_repo()
{
    local repo_dir=$1
    if [[ ! -d "${repo_dir}" ]];then
        echo "Repo directory(${repo_dir}) not exist"
        return 1
    fi
    
    git status > /dev/null 2&>1
    if [[ $? -ne 0 ]];then
        echo "Repo directory(${repo_dir}) is not git repo"
        return 1
    fi

    return 0    
}
