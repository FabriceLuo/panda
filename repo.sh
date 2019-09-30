#! /bin/bash
#
# repo.sh
# Copyright (C) 2019 luominghao <luominghao@live.com>
#
# Distributed under terms of the MIT license.
#
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


get_remote_repo_url()
{
    local repo_dir=$1
    local remote_repo_url=

    is_git_repo "${repo_dir}"
    if [[ $? -ne 0 ]]; then
        echo "repo is not git repo(${repo_dir})"
        return 1
    fi

    remote_repo_url=$(git remote -v show | awk '$3 == "(push)" {print $2}')
    if [[ $? -ne 0 ]]; then
        echo "get repo(${repo_dir}) remote url failed"
        return 1
    fi
    echo "${remote_repo_url}"
    return 0
}

get_repo_top_name() {
    local repo_dir=$1
    local repo_name=

    is_git_repo "${repo_dir}"
    if [[ $? -ne 0 ]]; then
        echo "repo is not git repo(${repo_dir})"
        return 1
    fi

    repo_name=$(basename $(git remote get-url origin) | sed 's/\.git$//g')
    if [[ $? -ne 0 ]]; then
        echo "parse repo(${repo_dir}) name from url failed"
        return 1
    fi

    echo "${repo_name}"
    return 0
}


export -f is_git_repo
