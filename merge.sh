#! /bin/bash
#
# merge.sh
# Copyright (C) 2019 luominghao <luominghao@live.com>
#
# Distributed under terms of the MIT license.
#

GITLAB_TOKEN="oB-QgDLotz7vo9HxuDgp"
GITLAB_BASE_URL="https://gitlab.com/api/v4"
GITLAB_AUTHOR_ID="4821787"

list_merges()
{
    local project_id=$1
    local merge_status=$2
    local merges=

    merges=$(curl -s "${GITLAB_BASE_URL}/projects/${project_id}/merge_requests?private_token=${GITLAB_TOKEN}&author_id=${GITLAB_AUTHOR_ID}&order_by=updated_at&state=${merge_status}" | jq -r '.[].id |=tostring | .[] | .id + ":" + .title')
    if [[ $? -ne 0 ]]; then
        echo "get project(${project_id}) merge list(${merge_status}) failed"
        return 1
    fi

    echo "${merges}"
    return 0
}

get_merge() {
    local merge_id=$1

    
    return 0
}

create_merge() {
    local project_id=$1
    local src_branch=$2
    local des_branch=$3
    local merge_title=$4
    local merge_desc=$5
    local assignee_id=$6
    local merge_info

    merge_info=$(curl -X POST -H "Content-type: application/x-www-form-urlencoded, charset: utf-8" -d "private_token=${GITLAB_TOKEN}&source_branch=${src_branch}&target_branch=${des_branch}&title=${merge_title}&description=${merge_desc}&assignee_id=${assignee_id}" "${GITLAB_BASE_URL}/projects/${project_id}/merge_requests")
    if [[ $? -ne 0 ]]; then
        echo "create merge request failed"
        return 1
    fi

    echo "${merge_info}"
    return 0
}

update_merge() {
    return 0
}

close_merge() {
    return 0
}

reopen_merge() {
    return 0
}

get_project_id() {
    local project_name=$1
    local project_url=$2
    local projects=
    local project_id=

    # 搜索project_name，然后对比project_url
    projects=$(curl -s "${GITLAB_BASE_URL}/projects?private_token=${GITLAB_TOKEN}&simple=true&search=${project_name}")
    if [[ $? -ne 0 ]]; then
        echo "search projects with regex(${project_name}) failed"
        return 1
    fi

    project_id=$(echo "${projects}" | jq "foreach .[] as \$item (null;if \$item.ssh_url_to_repo  == \"${project_url}\" then null else empty end; if \$item != null then \$item else empty end) | .id")
    if [[ $? -ne 0 || -z $project_id ]]; then
        echo "get project(${project_name}) id from projects(${projects}) failed"
        return 1
    fi

    echo "${project_id}"
    return 0
}
